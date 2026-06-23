//
//  ContentView.swift
//  lockinput
//
//  Created by dave on 2025/12/19.
//

import SwiftUI
import Carbon

enum AppTypography {
    static let status = Font.system(size: 13, weight: .semibold)
    static let primary = Font.system(size: 13)
    static let secondary = Font.system(size: 12)
    static let control = Font.system(size: 12)
    static let caption = Font.system(size: 10)
}

struct ContentView: View {
    @ObservedObject var inputManager = InputMethodManager.shared
    @ObservedObject var languageManager = LanguageManager.shared
    var openSettings: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            inputSourceList

            Divider()

            settingsEntry
        }
        .frame(width: 260)
    }

    var headerView: some View {
        VStack(spacing: 7) {
            HStack {
                Image(systemName: headerIconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(headerIconColor)
                    .frame(width: 22)

                Text(statusTitle)
                    .font(AppTypography.status)
                    .lineLimit(1)

                Spacer()

                Button(action: {
                    inputManager.toggle()
                }) {
                    Text(inputManager.isLocked
                         ? "button.unlock".localized(with: languageManager)
                         : "button.lock".localized(with: languageManager))
                        .font(AppTypography.control)
                        .lineLimit(1)
                        .frame(width: 54)
                }
                .buttonStyle(.borderedProminent)
                .tint(inputManager.isLocked ? .gray : .accentColor)
            }

            VStack(spacing: 4) {
                sourceSummaryRow(
                    label: "status.lockedInput".localized(with: languageManager),
                    value: lockedInputSourceName
                )
                sourceSummaryRow(
                    label: "status.currentInput".localized(with: languageManager),
                    value: inputManager.currentInputSourceName
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
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
            .padding(.vertical, 6)
        }
        .frame(maxHeight: 142)
    }

    var settingsEntry: some View {
        Button(action: openSettings) {
            HStack {
                Label("menu.settings".localized(with: languageManager), systemImage: "gearshape")
                    .font(AppTypography.control)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var statusTitle: String {
        if inputManager.isTemporarilyUsingABC {
            return "status.temporaryABC".localized(with: languageManager)
        }

        return inputManager.isLocked
            ? "status.locked".localized(with: languageManager)
            : "status.unlocked".localized(with: languageManager)
    }

    var headerIconName: String {
        if inputManager.isTemporarilyUsingABC {
            return "keyboard"
        }

        return inputManager.isLocked ? "lock.fill" : "lock.open"
    }

    var headerIconColor: Color {
        if inputManager.isTemporarilyUsingABC {
            return .accentColor
        }

        return inputManager.isLocked ? .accentColor : .secondary
    }

    var lockedInputSourceName: String {
        guard inputManager.isLocked else {
            return "status.unlocked".localized(with: languageManager)
        }

        guard let source = inputManager.lockedInputSource else {
            return "Unknown"
        }

        return inputManager.getInputSourceName(source)
    }

    func sourceSummaryRow(label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(AppTypography.caption)
                .foregroundColor(.secondary)
                .frame(width: 38, alignment: .leading)

            Text(value)
                .font(AppTypography.secondary)
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
    }

    func isCurrentSource(_ source: TISInputSource) -> Bool {
        guard let current = inputManager.getCurrentInputSource() else { return false }
        return inputManager.getInputSourceID(source) == inputManager.getInputSourceID(current)
    }

    func isLockedSource(_ source: TISInputSource) -> Bool {
        inputManager.getInputSourceID(source) == inputManager.lockedInputSourceID
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
                    .foregroundColor(isLocked ? .accentColor : .secondary)
                    .frame(width: 20)

                Text(inputManager.getInputSourceName(source))
                    .font(AppTypography.primary)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
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
