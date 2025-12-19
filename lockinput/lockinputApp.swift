//
//  lockinputApp.swift
//  lockinput
//
//  Created by dave on 2025/12/19.
//

import SwiftUI
import ServiceManagement

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

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupPopover()

        // 隐藏 Dock 图标
        NSApp.setActivationPolicy(.accessory)
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateStatusBarIcon()
            button.action = #selector(togglePopover)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // 监听锁定状态变化
        inputManager.$isLocked.receive(on: RunLoop.main).sink { [weak self] _ in
            self?.updateStatusBarIcon()
        }.store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    func updateStatusBarIcon() {
        if let button = statusItem.button {
            let symbolName = inputManager.isLocked ? "lock.fill" : "lock.open"
            button.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "输入法锁定")
        }
    }

    func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 320)
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

        let lockItem = NSMenuItem(
            title: inputManager.isLocked ? "解锁输入法" : "锁定当前输入法",
            action: #selector(toggleLock),
            keyEquivalent: ""
        )
        menu.addItem(lockItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q")
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

import Combine
