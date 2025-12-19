//
//  InputMethodManager.swift
//  lockinput
//
//  Created by dave on 2025/12/19.
//

import Foundation
import Carbon
import Combine

class InputMethodManager: ObservableObject {
    static let shared = InputMethodManager()

    @Published var isLocked = false
    @Published var lockedInputSource: TISInputSource?
    @Published var currentInputSourceName: String = ""
    @Published var availableInputSources: [TISInputSource] = []

    private var observer: AnyObject?

    init() {
        loadAvailableInputSources()
        updateCurrentInputSourceName()
        setupInputSourceChangeObserver()
    }

    deinit {
        if let observer = observer {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }

    func loadAvailableInputSources() {
        let conditions = [
            kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource,
            kTISPropertyInputSourceIsSelectCapable: true
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

    func getCurrentInputSource() -> TISInputSource? {
        return TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()
    }

    func updateCurrentInputSourceName() {
        if let current = getCurrentInputSource() {
            currentInputSourceName = getInputSourceName(current)
        }
    }

    func selectInputSource(_ source: TISInputSource) {
        TISSelectInputSource(source)
        updateCurrentInputSourceName()
    }

    func lockCurrentInputSource() {
        lockedInputSource = getCurrentInputSource()
        isLocked = true
        updateCurrentInputSourceName()
    }

    func lockInputSource(_ source: TISInputSource) {
        selectInputSource(source)
        lockedInputSource = source
        isLocked = true
        updateCurrentInputSourceName()
    }

    func unlock() {
        isLocked = false
        lockedInputSource = nil
    }

    func toggle() {
        if isLocked {
            unlock()
        } else {
            lockCurrentInputSource()
        }
    }

    private func setupInputSourceChangeObserver() {
        observer = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleInputSourceChange()
        }
    }

    private func handleInputSourceChange() {
        updateCurrentInputSourceName()

        guard isLocked, let locked = lockedInputSource else { return }

        if let current = getCurrentInputSource() {
            let currentID = getInputSourceID(current)
            let lockedID = getInputSourceID(locked)

            if currentID != lockedID {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                    self?.selectInputSource(locked)
                }
            }
        }
    }
}
