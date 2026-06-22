//
//  lockinputApp.swift
//  lockinput
//
//  Created by dave on 2025/12/19.
//

import SwiftUI
import ServiceManagement
import Combine

@main
struct lockinputApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var inputManager = InputMethodManager.shared
    var languageManager = LanguageManager.shared
    var shortcutManager = GlobalShortcutManager.shared
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        shortcutManager.start()
        setupStatusBar()
        setupPopover()

        NSApp.setActivationPolicy(.accessory)
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
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
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityDesc)
        }
    }

    func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 450)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())
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

    @objc func quit() {
        NSApp.terminate(nil)
    }
}
