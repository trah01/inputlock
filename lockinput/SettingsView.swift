//
//  SettingsView.swift
//  lockinput
//

import SwiftUI
import AppKit
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var inputManager = InputMethodManager.shared
    @ObservedObject var languageManager = LanguageManager.shared
    @ObservedObject var shortcutManager = GlobalShortcutManager.shared
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("restorePreviousLockState") var restorePreviousLockState = false
    @AppStorage("temporaryInputSourceID") var temporaryInputSourceID = ""
    @State private var isRecordingShortcut = false
    @State private var shortcutRecordingMonitors: [Any] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("settings.title".localized(with: languageManager))
                    .font(.system(size: 20, weight: .semibold))

                settingsSection {
                    HStack {
                        Label("settings.language".localized(with: languageManager), systemImage: "globe")
                            .font(AppTypography.primary)

                        Spacer()

                        Picker("", selection: $languageManager.currentLanguage) {
                            ForEach(AppLanguage.allCases) { language in
                                Text(language.displayName).tag(language)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }

                    Divider()

                    Toggle(isOn: $launchAtLogin) {
                        Label("settings.launchAtLogin".localized(with: languageManager), systemImage: "power")
                            .font(AppTypography.primary)
                    }
                    .toggleStyle(.checkbox)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(newValue)
                    }

                    Divider()

                    Toggle(isOn: $restorePreviousLockState) {
                        Label("settings.restorePreviousLockState".localized(with: languageManager), systemImage: "arrow.clockwise")
                            .font(AppTypography.primary)
                    }
                    .toggleStyle(.checkbox)
                }

                settingsSection {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("settings.temporaryInputShortcut".localized(with: languageManager), systemImage: "keyboard")
                            .font(AppTypography.primary)

                        HStack(spacing: 8) {
                            Button(action: {
                                startShortcutRecording()
                            }) {
                                Text(shortcutButtonTitle)
                                    .font(AppTypography.control)
                                    .lineLimit(1)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.bordered)

                            Button(action: {
                                shortcutManager.clearShortcut()
                                stopShortcutRecording()
                            }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 11, weight: .semibold))
                                    .frame(width: 22, height: 22)
                            }
                            .buttonStyle(.bordered)
                            .disabled(shortcutManager.shortcut == nil && !isRecordingShortcut)
                            .help("settings.clearShortcut".localized(with: languageManager))
                        }

                        HStack {
                            Text("settings.temporaryInputSource".localized(with: languageManager))
                                .font(AppTypography.control)
                                .foregroundColor(.secondary)

                            Spacer()

                            Picker("", selection: $temporaryInputSourceID) {
                                Text("settings.temporaryInputSourceAutomatic".localized(with: languageManager))
                                    .tag("")

                                ForEach(inputManager.availableInputSources, id: \.self) { source in
                                    Text(inputManager.getInputSourceName(source))
                                        .tag(inputManager.getInputSourceID(source))
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 190)
                        }

                        Text("settings.temporaryInputHint".localized(with: languageManager))
                            .font(AppTypography.secondary)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                settingsSection {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("settings.about".localized(with: languageManager), systemImage: "info.circle")
                            .font(AppTypography.primary)

                        Link("https://github.com/trah01/inputlock-extend", destination: URL(string: "https://github.com/trah01/inputlock-extend")!)
                            .font(AppTypography.control)
                    }
                }
            }
            .padding(24)
        }
        .frame(width: 460, height: 520)
        .onDisappear {
            stopShortcutRecording()
        }
    }

    var shortcutButtonTitle: String {
        if isRecordingShortcut {
            return "settings.recordingShortcut".localized(with: languageManager)
        }

        return shortcutManager.shortcut?.displayText
            ?? "settings.setShortcut".localized(with: languageManager)
    }

    func settingsSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
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

#if DEBUG && canImport(PreviewsMacros)
#Preview {
    SettingsView()
}
#endif
