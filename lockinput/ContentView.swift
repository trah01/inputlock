//
//  ContentView.swift
//  lockinput
//
//  Created by dave on 2025/12/19.
//

import SwiftUI
import Carbon
import ServiceManagement

struct ContentView: View {
    @ObservedObject var inputManager = InputMethodManager.shared
    @AppStorage("launchAtLogin") var launchAtLogin = false

    var body: some View {
        VStack(spacing: 0) {
            // 头部状态
            headerView

            Divider()

            // 输入法列表
            inputSourceList

            Divider()

            // 底部设置
            footerView
        }
        .frame(width: 280)
    }

    var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: inputManager.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 24))
                    .foregroundColor(inputManager.isLocked ? .green : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(inputManager.isLocked ? "已锁定" : "未锁定")
                        .font(.headline)

                    Text(inputManager.currentInputSourceName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: {
                    inputManager.toggle()
                }) {
                    Text(inputManager.isLocked ? "解锁" : "锁定")
                        .frame(width: 50)
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
        HStack {
            Toggle(isOn: $launchAtLogin) {
                Label("开机启动", systemImage: "power")
                    .font(.caption)
            }
            .toggleStyle(.checkbox)
            .onChange(of: launchAtLogin) { _, newValue in
                setLaunchAtLogin(newValue)
            }

            Spacer()

            Button(action: {
                NSApp.terminate(nil)
            }) {
                Label("退出", systemImage: "xmark.circle")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding()
    }

    func isCurrentSource(_ source: TISInputSource) -> Bool {
        guard let current = inputManager.getCurrentInputSource() else { return false }
        return inputManager.getInputSourceID(source) == inputManager.getInputSourceID(current)
    }

    func isLockedSource(_ source: TISInputSource) -> Bool {
        guard let locked = inputManager.lockedInputSource else { return false }
        return inputManager.getInputSourceID(source) == inputManager.getInputSourceID(locked)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
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
                    .foregroundColor(.primary)

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

#Preview {
    ContentView()
}
