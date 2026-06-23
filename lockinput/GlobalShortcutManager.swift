//
//  GlobalShortcutManager.swift
//  lockinput
//

import AppKit
import Carbon
import Combine

struct KeyboardShortcut: Equatable {
    private static let globeKeyCode: UInt32 = 63
    private static let capsLockKeyCode: UInt32 = 57
    private static let leftShiftKeyCode: UInt32 = 56
    private static let rightShiftKeyCode: UInt32 = 60

    let keyCode: UInt32
    let modifiers: UInt32
    let keyDisplay: String

    var isGlobe: Bool {
        keyCode == Self.globeKeyCode && modifiers == 0
    }

    var isCapsLockOnly: Bool {
        keyCode == Self.capsLockKeyCode && modifiers == 0
    }

    var isShiftOnly: Bool {
        Self.isShiftKeyCode(keyCode) && modifiers == 0
    }

    var usesFlagsChangedMonitor: Bool {
        isGlobe || isCapsLockOnly || isShiftOnly
    }

    var displayText: String {
        if usesFlagsChangedMonitor {
            return keyDisplay
        }

        var parts: [String] = []

        if modifiers & UInt32(cmdKey) != 0 {
            parts.append("Command")
        }
        if modifiers & UInt32(controlKey) != 0 {
            parts.append("Control")
        }
        if modifiers & UInt32(optionKey) != 0 {
            parts.append("Option")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            parts.append("Shift")
        }

        parts.append(keyDisplay)
        return parts.joined(separator: " + ")
    }

    static func isShiftKeyCode(_ keyCode: UInt32) -> Bool {
        keyCode == leftShiftKeyCode || keyCode == rightShiftKeyCode
    }
}

final class GlobalShortcutManager: ObservableObject {
    static let shared = GlobalShortcutManager()

    private enum DefaultsKey {
        static let keyCode = "temporaryABCShortcutKeyCode"
        static let modifiers = "temporaryABCShortcutModifiers"
        static let keyDisplay = "temporaryABCShortcutKeyDisplay"
    }

    private static let hotKeySignature: OSType = 0x4C494E50
    private let hotKeyID = EventHotKeyID(signature: GlobalShortcutManager.hotKeySignature, id: 1)

    @Published private(set) var shortcut: KeyboardShortcut?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var modifierGlobalMonitor: Any?
    private var modifierLocalMonitor: Any?
    private var isModifierShortcutPressed = false
    private var lastCapsLockShortcutAt = Date.distantPast

    private init() {
        shortcut = Self.loadShortcut()
    }

    deinit {
        unregisterShortcut()
        stopModifierMonitors()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    func start() {
        installEventHandlerIfNeeded()
        registerStoredShortcut()
    }

    @discardableResult
    func updateShortcut(from event: NSEvent) -> Bool {
        guard let shortcut = KeyboardShortcut(event: event) else { return false }

        self.shortcut = shortcut
        UserDefaults.standard.set(Int(shortcut.keyCode), forKey: DefaultsKey.keyCode)
        UserDefaults.standard.set(Int(shortcut.modifiers), forKey: DefaultsKey.modifiers)
        UserDefaults.standard.set(shortcut.keyDisplay, forKey: DefaultsKey.keyDisplay)
        registerStoredShortcut()
        return true
    }

    func clearShortcut() {
        shortcut = nil
        UserDefaults.standard.removeObject(forKey: DefaultsKey.keyCode)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.modifiers)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.keyDisplay)
        unregisterShortcut()
        stopModifierMonitors()
    }

    func handleHotKeyPressed() {
        InputMethodManager.shared.switchTemporarilyToSelectedInputSource()
    }

    private static func loadShortcut() -> KeyboardShortcut? {
        guard UserDefaults.standard.object(forKey: DefaultsKey.keyCode) != nil,
              UserDefaults.standard.object(forKey: DefaultsKey.modifiers) != nil,
              let keyDisplay = UserDefaults.standard.string(forKey: DefaultsKey.keyDisplay),
              !keyDisplay.isEmpty else {
            return nil
        }

        let keyCode = UInt32(UserDefaults.standard.integer(forKey: DefaultsKey.keyCode))
        let modifiers = UInt32(UserDefaults.standard.integer(forKey: DefaultsKey.modifiers))
        return KeyboardShortcut(keyCode: keyCode, modifiers: modifiers, keyDisplay: keyDisplay)
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandlerRef == nil else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                guard let event else { return OSStatus(eventNotHandledErr) }

                var eventHotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &eventHotKeyID
                )

                guard status == noErr,
                      eventHotKeyID.signature == GlobalShortcutManager.hotKeySignature,
                      eventHotKeyID.id == 1 else {
                    return OSStatus(eventNotHandledErr)
                }

                DispatchQueue.main.async {
                    GlobalShortcutManager.shared.handleHotKeyPressed()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandlerRef
        )
    }

    private func registerStoredShortcut() {
        unregisterShortcut()
        stopModifierMonitors()
        guard let shortcut else { return }

        if shortcut.usesFlagsChangedMonitor {
            startModifierMonitors()
            return
        }

        var newHotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &newHotKeyRef
        )

        if status == noErr {
            hotKeyRef = newHotKeyRef
        }
    }

    private func unregisterShortcut() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func startModifierMonitors() {
        guard modifierGlobalMonitor == nil, modifierLocalMonitor == nil else { return }

        modifierGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleModifierFlagsChanged(event)
            }
        }

        modifierLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleModifierFlagsChanged(event)
            return event
        }
    }

    private func stopModifierMonitors() {
        if let modifierGlobalMonitor {
            NSEvent.removeMonitor(modifierGlobalMonitor)
            self.modifierGlobalMonitor = nil
        }

        if let modifierLocalMonitor {
            NSEvent.removeMonitor(modifierLocalMonitor)
            self.modifierLocalMonitor = nil
        }

        isModifierShortcutPressed = false
    }

    private func handleModifierFlagsChanged(_ event: NSEvent) {
        guard let shortcut,
              shortcut.usesFlagsChangedMonitor,
              event.isRelevantModifierShortcutEvent(shortcut) else { return }

        let isPressed = event.matchesModifierOnlyShortcut(shortcut)
        if shortcut.isCapsLockOnly, isPressed {
            triggerCapsLockShortcutIfNeeded()
            return
        }

        if isPressed, !isModifierShortcutPressed {
            handleHotKeyPressed()
        }
        isModifierShortcutPressed = isPressed
    }

    private func triggerCapsLockShortcutIfNeeded() {
        let now = Date()
        guard now.timeIntervalSince(lastCapsLockShortcutAt) > 0.2 else { return }

        lastCapsLockShortcutAt = now
        handleHotKeyPressed()
    }
}

extension KeyboardShortcut {
    init?(event: NSEvent) {
        if event.isGlobePressedEvent {
            self.keyCode = 63
            self.modifiers = 0
            self.keyDisplay = "Globe"
            return
        }

        if event.isCapsLockKeyEvent {
            self.keyCode = UInt32(event.keyCode)
            self.modifiers = 0
            self.keyDisplay = "Caps Lock"
            return
        }

        if event.isShiftOnlyPressedEvent {
            self.keyCode = UInt32(event.keyCode)
            self.modifiers = 0
            self.keyDisplay = "Shift"
            return
        }

        let modifiers = Self.carbonModifiers(from: event.modifierFlags)
        guard modifiers != 0 else { return nil }

        let keyDisplay = Self.keyDisplay(from: event)
        guard !keyDisplay.isEmpty else { return nil }

        self.keyCode = UInt32(event.keyCode)
        self.modifiers = modifiers
        self.keyDisplay = keyDisplay
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0

        if flags.contains(.command) {
            modifiers |= UInt32(cmdKey)
        }
        if flags.contains(.control) {
            modifiers |= UInt32(controlKey)
        }
        if flags.contains(.option) {
            modifiers |= UInt32(optionKey)
        }
        if flags.contains(.shift) {
            modifiers |= UInt32(shiftKey)
        }

        return modifiers
    }

    private static func keyDisplay(from event: NSEvent) -> String {
        switch event.keyCode {
        case 36:
            return "Return"
        case 48:
            return "Tab"
        case 49:
            return "Space"
        case 51:
            return "Delete"
        case 53:
            return "Escape"
        case 123:
            return "Left"
        case 124:
            return "Right"
        case 125:
            return "Down"
        case 126:
            return "Up"
        default:
            return (event.charactersIgnoringModifiers ?? "").uppercased()
        }
    }
}

private extension NSEvent {
    var isGlobeKeyEvent: Bool {
        keyCode == 63
    }

    var isCapsLockKeyEvent: Bool {
        keyCode == 57
    }

    var isShiftKeyEvent: Bool {
        KeyboardShortcut.isShiftKeyCode(UInt32(keyCode))
    }

    var isGlobePressedEvent: Bool {
        isGlobeKeyEvent && modifierFlags.contains(.function)
    }

    var isShiftOnlyPressedEvent: Bool {
        isShiftKeyEvent && modifierFlags.contains(.shift)
    }

    func isRelevantModifierShortcutEvent(_ shortcut: KeyboardShortcut) -> Bool {
        if shortcut.isGlobe {
            return isGlobeKeyEvent
        }

        if shortcut.isCapsLockOnly {
            return isCapsLockKeyEvent
        }

        if shortcut.isShiftOnly {
            return isShiftKeyEvent
        }

        return false
    }

    func matchesModifierOnlyShortcut(_ shortcut: KeyboardShortcut) -> Bool {
        if shortcut.isGlobe {
            return isGlobePressedEvent
        }

        if shortcut.isCapsLockOnly {
            return isCapsLockKeyEvent
        }

        if shortcut.isShiftOnly {
            return isShiftOnlyPressedEvent
        }

        return false
    }
}
