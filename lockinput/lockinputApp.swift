//
//  lockinputApp.swift
//  lockinput
//
//  Created by dave on 2025/12/19.
//

import SwiftUI
import Combine

@main
struct lockinputApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var inputManager = InputMethodManager.shared
    var languageManager = LanguageManager.shared
    var shortcutManager = GlobalShortcutManager.shared
    private var settingsWindow: NSWindow?
    private var settingsShortcutMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        shortcutManager.start()
        setupStatusBar()
        setupPopover()
        setupSettingsShortcut()

        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let settingsShortcutMonitor {
            NSEvent.removeMonitor(settingsShortcutMonitor)
            self.settingsShortcutMonitor = nil
        }
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.imagePosition = .imageOnly
            updateStatusBarIcon()
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        inputManager.$isLocked.receive(on: RunLoop.main).sink { [weak self] _ in
            self?.updateStatusBarIcon()
        }.store(in: &cancellables)
    }

    func updateStatusBarIcon() {
        if let button = statusItem.button {
            let symbolName = inputManager.isLocked ? "lock.fill" : "lock.open"
            let accessibilityDesc = "accessibility.lockIcon".localized(with: languageManager)
            let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityDesc)
            image?.size = NSSize(width: 16, height: 16)
            image?.isTemplate = true
            button.image = image
        }
    }

    func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 300)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView(openSettings: { [weak self] in
            self?.openSettings()
        }))
    }

    func setupSettingsShortcut() {
        settingsShortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if event.keyCode == 43, flags == .command {
                self?.openSettings()
                return nil
            }

            return event
        }
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }

        if let event = NSApp.currentEvent {
            if event.type == .rightMouseUp {
                showContextMenu()
                return
            }
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func showContextMenu() {
        let menu = NSMenu()

        let lockTitle = inputManager.isLocked
            ? "menu.unlock".localized(with: languageManager)
            : "menu.lockCurrent".localized(with: languageManager)
        let lockItem = NSMenuItem(
            title: lockTitle,
            action: #selector(toggleLock),
            keyEquivalent: ""
        )
        menu.addItem(lockItem)

        menu.addItem(NSMenuItem.separator())

        let settingsTitle = "menu.settings".localized(with: languageManager)
        let settingsItem = NSMenuItem(title: settingsTitle, action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.keyEquivalentModifierMask = [.command]
        menu.addItem(settingsItem)

        let quitTitle = "menu.quit".localized(with: languageManager)
        let quitItem = NSMenuItem(title: quitTitle, action: #selector(quit), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc func toggleLock() {
        inputManager.toggle()
    }

    @objc func openSettings() {
        if popover.isShown {
            popover.performClose(nil)
        }

        if settingsWindow == nil {
            let hostingView = NSHostingView(rootView: SettingsView())
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 460, height: 520),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.contentView = hostingView
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }

        settingsWindow?.title = "settings.title".localized(with: languageManager)
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
