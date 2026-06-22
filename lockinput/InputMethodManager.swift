//
//  InputMethodManager.swift
//  lockinput
//
//  Created by dave on 2025/12/19.
//

import AppKit
import Carbon
import Combine

class InputMethodManager: ObservableObject {
    static let shared = InputMethodManager()
    private enum DefaultsKey {
        static let restorePreviousLockState = "restorePreviousLockState"
        static let previousLockedInputSourceID = "previousLockedInputSourceID"
    }

    @Published var isLocked = false
    @Published var lockedInputSource: TISInputSource?
    @Published var lockedInputSourceID: String?
    @Published var currentInputSourceName: String = ""
    @Published var availableInputSources: [TISInputSource] = []

    private var lockState = InputSourceLockState()
    private var notificationObservers: [NSObjectProtocol] = []
    private var enforcementTimer: Timer?
    private var temporaryABCTimer: Timer?
    private var temporaryABCStartedAt: Date?
    private var isEnforcingLockedSource = false
    private var isTemporarilyUsingABC = false

    init() {
        loadAvailableInputSources()
        updateCurrentInputSourceName()
        setupInputSourceChangeObservers()
        restorePreviousLockStateIfNeeded()
    }

    deinit {
        for observer in notificationObservers {
            DistributedNotificationCenter.default().removeObserver(observer)
            NotificationCenter.default.removeObserver(observer)
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        enforcementTimer?.invalidate()
        temporaryABCTimer?.invalidate()
    }

    func loadAvailableInputSources() {
        let conditions = [
            kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource as Any,
            kTISPropertyInputSourceIsSelectCapable: kCFBooleanTrue as Any
        ] as CFDictionary

        guard let sources = TISCreateInputSourceList(conditions, false)?.takeRetainedValue() as? [TISInputSource] else {
            return
        }

        availableInputSources = sources.filter { source in
            if let enabled = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsEnabled) {
                return Unmanaged<CFBoolean>.fromOpaque(enabled).takeUnretainedValue() == kCFBooleanTrue
            }
            return false
        }
    }

    func getInputSourceName(_ source: TISInputSource) -> String {
        if let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) {
            return Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
        }
        return "Unknown"
    }

    func getInputSourceID(_ source: TISInputSource) -> String {
        if let idPtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) {
            return Unmanaged<CFString>.fromOpaque(idPtr).takeUnretainedValue() as String
        }
        return ""
    }

    func getInputSourceType(_ source: TISInputSource) -> String {
        if let typePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceType) {
            return Unmanaged<CFString>.fromOpaque(typePtr).takeUnretainedValue() as String
        }
        return ""
    }

    func isASCIICapableInputSource(_ source: TISInputSource) -> Bool {
        guard let capablePtr = TISGetInputSourceProperty(source, kTISPropertyInputSourceIsASCIICapable) else {
            return false
        }
        return Unmanaged<CFBoolean>.fromOpaque(capablePtr).takeUnretainedValue() == kCFBooleanTrue
    }

    func isKeyboardLayout(_ source: TISInputSource) -> Bool {
        getInputSourceType(source) == (kTISTypeKeyboardLayout as String)
    }

    func getCurrentInputSource() -> TISInputSource? {
        return TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
    }

    func updateCurrentInputSourceName() {
        if let current = getCurrentInputSource() {
            currentInputSourceName = getInputSourceName(current)
        } else {
            currentInputSourceName = "Unknown"
        }
    }

    @discardableResult
    func selectInputSource(_ source: TISInputSource) -> Bool {
        let result = TISSelectInputSource(source)
        updateCurrentInputSourceName()
        return result == noErr
    }

    func lockCurrentInputSource() {
        guard let current = getCurrentInputSource() else { return }
        lock(source: current)
        updateCurrentInputSourceName()
        enforceLockedInputSource()
    }

    func lockInputSource(_ source: TISInputSource) {
        selectInputSource(source)
        lock(source: source)
        updateCurrentInputSourceName()
        enforceLockedInputSource()
    }

    func unlock() {
        lockState.unlock()
        UserDefaults.standard.removeObject(forKey: DefaultsKey.previousLockedInputSourceID)
        syncPublishedLockState()
        stopEnforcementTimer()
        stopTemporaryABCMode()
    }

    func toggle() {
        if isLocked {
            unlock()
        } else {
            lockCurrentInputSource()
        }
    }

    func switchTemporarilyToABC() {
        guard lockState.isLocked,
              let temporarySource = preferredTemporaryASCIISource() else {
            return
        }

        isTemporarilyUsingABC = true
        temporaryABCStartedAt = Date()
        temporaryABCTimer?.invalidate()

        let temporarySourceID = getInputSourceID(temporarySource)
        if getCurrentInputSource().map(getInputSourceID) != temporarySourceID {
            _ = selectInputSource(temporarySource)
        }

        scheduleTemporaryABCRestoreCheck(after: 15.0)
    }

    private func setupInputSourceChangeObservers() {
        let distributedCenter = DistributedNotificationCenter.default()
        notificationObservers.append(distributedCenter.addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleInputSourceChange()
        })

        notificationObservers.append(distributedCenter.addObserver(
            forName: NSNotification.Name(kTISNotifyEnabledKeyboardInputSourcesChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.loadAvailableInputSources()
            self?.refreshLockedInputSource()
            self?.handleInputSourceChange()
        })

        notificationObservers.append(NotificationCenter.default.addObserver(
            forName: NSTextInputContext.keyboardSelectionDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleInputSourceChange()
        })

        notificationObservers.append(NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleInputSourceChange()
        })
    }

    private func handleInputSourceChange() {
        updateCurrentInputSourceName()
        enforceLockedInputSource()
    }

    private func lock(source: TISInputSource) {
        let sourceID = getInputSourceID(source)
        guard !sourceID.isEmpty else { return }

        lockState.lock(inputSourceID: sourceID)
        UserDefaults.standard.set(sourceID, forKey: DefaultsKey.previousLockedInputSourceID)
        syncPublishedLockState()
        startEnforcementTimer()
    }

    private func restorePreviousLockStateIfNeeded() {
        guard UserDefaults.standard.bool(forKey: DefaultsKey.restorePreviousLockState),
              let sourceID = UserDefaults.standard.string(forKey: DefaultsKey.previousLockedInputSourceID),
              !sourceID.isEmpty else {
            return
        }

        lockState.lock(inputSourceID: sourceID)
        syncPublishedLockState()
        startEnforcementTimer()
        enforceLockedInputSource()
    }

    private func syncPublishedLockState() {
        isLocked = lockState.isLocked
        lockedInputSourceID = lockState.lockedInputSourceID
        refreshLockedInputSource()
    }

    private func refreshLockedInputSource() {
        guard let lockedInputSourceID = lockState.lockedInputSourceID else {
            lockedInputSource = nil
            return
        }

        lockedInputSource = inputSource(withID: lockedInputSourceID)
    }

    private func inputSource(withID inputSourceID: String) -> TISInputSource? {
        if let source = availableInputSources.first(where: { getInputSourceID($0) == inputSourceID }) {
            return source
        }

        loadAvailableInputSources()
        return availableInputSources.first { getInputSourceID($0) == inputSourceID }
    }

    private func enforceLockedInputSource() {
        guard lockState.isLocked, !isEnforcingLockedSource else { return }
        guard !isTemporarilyUsingABC else { return }
        guard let lockedInputSourceID = lockState.lockedInputSourceID else { return }
        guard let currentSource = getCurrentInputSource() else { return }
        let currentID = getInputSourceID(currentSource)

        if shouldUseSecureTextInputSource(whileLockedTo: lockedInputSourceID),
            let temporarySource = preferredTemporaryASCIISource() {
            if currentID != getInputSourceID(temporarySource) {
                selectInputSourceAfterDelay(temporarySource, lockedInputSourceID: lockedInputSourceID)
            } else {
                refreshLockedInputSource()
            }
            return
        }

        guard currentID != lockedInputSourceID else { return }

        guard let lockedSource = inputSource(withID: lockedInputSourceID) else { return }
        selectInputSourceAfterDelay(lockedSource, lockedInputSourceID: lockedInputSourceID)
    }

    private func shouldUseSecureTextInputSource(whileLockedTo lockedInputSourceID: String) -> Bool {
        guard IsSecureEventInputEnabled() else { return false }
        guard let lockedSource = inputSource(withID: lockedInputSourceID) else { return false }

        return !isKeyboardLayout(lockedSource)
    }

    private func preferredTemporaryASCIISource() -> TISInputSource? {
        let preferredInputSourceIDs = [
            "com.apple.keylayout.ABC",
            "com.apple.keylayout.US"
        ]

        for inputSourceID in preferredInputSourceIDs {
            if let source = inputSource(withID: inputSourceID),
               isKeyboardLayout(source),
               isASCIICapableInputSource(source) {
                return source
            }
        }

        return availableInputSources.first {
            isKeyboardLayout($0) && isASCIICapableInputSource($0)
        }
    }

    private func selectInputSourceAfterDelay(_ source: TISInputSource, lockedInputSourceID: String) {
        let sourceID = getInputSourceID(source)

        isEnforcingLockedSource = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            guard let self else { return }
            guard self.lockState.matchesLockedInputSourceID(lockedInputSourceID) else {
                self.isEnforcingLockedSource = false
                return
            }

            if !self.selectInputSource(source),
               let refreshedSource = self.inputSource(withID: sourceID) {
                _ = self.selectInputSource(refreshedSource)
            }
            self.refreshLockedInputSource()
            self.isEnforcingLockedSource = false
        }
    }

    private func startEnforcementTimer() {
        guard enforcementTimer == nil else { return }

        enforcementTimer = Timer(timeInterval: 0.35, repeats: true) { [weak self] _ in
            self?.enforceLockedInputSource()
        }
        if let enforcementTimer {
            RunLoop.main.add(enforcementTimer, forMode: .common)
        }
    }

    private func stopEnforcementTimer() {
        enforcementTimer?.invalidate()
        enforcementTimer = nil
    }

    private func scheduleTemporaryABCRestoreCheck(after interval: TimeInterval) {
        temporaryABCTimer?.invalidate()
        temporaryABCTimer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            self?.restoreLockedInputSourceWhenIdle()
        }
        if let temporaryABCTimer {
            RunLoop.main.add(temporaryABCTimer, forMode: .common)
        }
    }

    private func restoreLockedInputSourceWhenIdle() {
        guard isTemporarilyUsingABC else { return }

        if isUserCurrentlyTyping {
            scheduleTemporaryABCRestoreCheck(after: 0.5)
            return
        }

        stopTemporaryABCMode()
        enforceLockedInputSource()
    }

    private var isUserCurrentlyTyping: Bool {
        guard let temporaryABCStartedAt else { return false }

        let secondsSinceLastKeyDown = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: .keyDown
        )

        guard secondsSinceLastKeyDown >= 0 else { return true }

        let elapsedSinceTemporarySwitch = Date().timeIntervalSince(temporaryABCStartedAt)
        return secondsSinceLastKeyDown < 1.2 || secondsSinceLastKeyDown < elapsedSinceTemporarySwitch
    }

    private func stopTemporaryABCMode() {
        isTemporarilyUsingABC = false
        temporaryABCTimer?.invalidate()
        temporaryABCTimer = nil
        temporaryABCStartedAt = nil
    }
}
