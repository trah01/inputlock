//
//  ContentView.swift
//  lockinput
//
//  Created by dave on 2025/12/19.
//

import SwiftUI
import Carbon
import ServiceManagement

private enum AppTypography {
    static let status = Font.system(size: 14, weight: .semibold)
    static let primary = Font.system(size: 13)
    static let secondary = Font.system(size: 12)
    static let control = Font.system(size: 12)
}

struct ContentView: View {
    @ObservedObject var inputManager = InputMethodManager.shared
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var shortcutManager = GlobalShortcutManager.shared
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("restorePreviousLockState") var restorePreviousLockState = false
    @State private var isRecordingShortcut = false
    @State private var shortcutRecordingMonitors: [Any] = []

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            inputSourceList

            Divider()

            footerView
        }
        .frame(width: 280)
        .onDisappear {
            stopShortcutRecording()
        }
    }

    var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: inputManager.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 24))
                    .foregroundColor(inputManager.isLocked ? .green : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(inputManager.isLocked
                         ? "status.locked".localized(with: languageManager)
                         : "status.unlocked".localized(with: languageManager))
                        .font(AppTypography.status)
                        .lineLimit(1)

                    Text(inputManager.currentInputSourceName)
                        .font(AppTypography.secondary)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                Spacer()

                Button(action: {
                    inputManager.toggle()
                }) {
                    Text(inputManager.isLocked
                         ? "button.unlock".localized(with: languageManager)
                         : "button.lock".localized(with: languageManager))
                        .font(AppTypography.control)
                        .lineLimit(1)
                        .frame(width: 64)
                }
                .buttonStyle(.borderedProminent)
                .tint(inputManager.isLocked ? .orange : .blue)
            }
        }
        .padding()
    }

    var inputSourceList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(inputManager.availableInputSources, id: \.self) { source in
                    InputSourceRow(
                        source: source,
                        isSelected: isCurrentSource(source),
                        isLocked: isLockedSource(source)
                    ) {
                        inputManager.lockInputSource(source)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 180)
    }

    var footerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("settings.language".localized(with: languageManager))
                    .font(AppTypography.control)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                Picker("", selection: $languageManager.currentLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
                .font(AppTypography.control)
            }

            HStack {
                Toggle(isOn: $launchAtLogin) {
                    Label("settings.launchAtLogin".localized(with: languageManager), systemImage: "power")
                        .font(AppTypography.control)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .toggleStyle(.checkbox)
                .onChange(of: launchAtLogin) { newValue in
                    setLaunchAtLogin(newValue)
                }

                Spacer()

                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Label("button.quit".localized(with: languageManager), systemImage: "xmark.circle")
                        .font(AppTypography.control)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }

            HStack {
                Toggle(isOn: $restorePreviousLockState) {
                    Label("settings.restorePreviousLockState".localized(with: languageManager), systemImage: "arrow.clockwise")
                        .font(AppTypography.control)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .toggleStyle(.checkbox)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("settings.temporaryABCShortcut".localized(with: languageManager))
                    .font(AppTypography.control)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Button(action: {
                        startShortcutRecording()
                    }) {
                        Label(shortcutButtonTitle, systemImage: "keyboard")
                            .font(AppTypography.control)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.bordered)

                    Button(action: {
                        shortcutManager.clearShortcut()
                        stopShortcutRecording()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.bordered)
                    .disabled(shortcutManager.shortcut == nil && !isRecordingShortcut)
                    .help("settings.clearShortcut".localized(with: languageManager))
                }

                Text("settings.temporaryABCHint".localized(with: languageManager))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
    }

    var shortcutButtonTitle: String {
        if isRecordingShortcut {
            return "settings.recordingShortcut".localized(with: languageManager)
        }

        return shortcutManager.shortcut?.displayText
            ?? "settings.setShortcut".localized(with: languageManager)
    }

    func isCurrentSource(_ source: TISInputSource) -> Bool {
        guard let current = inputManager.getCurrentInputSource() else { return false }
        return inputManager.getInputSourceID(source) == inputManager.getInputSourceID(current)
    }

    func isLockedSource(_ source: TISInputSource) -> Bool {
        inputManager.getInputSourceID(source) == inputManager.lockedInputSourceID
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to set launch at login: \(error)")
            }
        }
    }

    func startShortcutRecording() {
        stopShortcutRecording()
        isRecordingShortcut = true

        let keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                stopShortcutRecording()
                return nil
            }

            if event.keyCode == 51 {
                shortcutManager.clearShortcut()
                stopShortcutRecording()
                return nil
            }

            if shortcutManager.updateShortcut(from: event) {
                stopShortcutRecording()
            }
            return nil
        }

        let flagsChangedMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            if shortcutManager.updateShortcut(from: event) {
                stopShortcutRecording()
                return nil
            }

            return event
        }

        shortcutRecordingMonitors = [keyDownMonitor, flagsChangedMonitor].compactMap { $0 }
    }

    func stopShortcutRecording() {
        for monitor in shortcutRecordingMonitors {
            NSEvent.removeMonitor(monitor)
        }
        shortcutRecordingMonitors.removeAll()
        isRecordingShortcut = false
    }
}

struct InputSourceRow: View {
    let source: TISInputSource
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    @ObservedObject var inputManager = InputMethodManager.shared

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isLocked ? "lock.fill" : "keyboard")
                    .foregroundColor(isLocked ? .green : .secondary)
                    .frame(width: 20)

                Text(inputManager.getInputSourceName(source))
                    .font(AppTypography.primary)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }
}

#if DEBUG && canImport(PreviewsMacros)
#Preview {
    ContentView()
}
#endif
