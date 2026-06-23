# LockInput

Default README: [简体中文](README.md)

Other languages: English | [Français](README.fr.md) | [Deutsch](README.de.md) | [日本語](README.ja.md)

LockInput is a lightweight macOS menu bar app that locks the current input method and helps prevent accidental input source switching while writing, coding, or moving between apps.

## Features

- Locks the current input method and switches back if another source becomes active
- Supports a custom shortcut that temporarily switches to a selected input source and restores the locked input after 5 seconds of idle time
- Supports Globe, Caps Lock, Shift, and regular key combinations as the temporary switch shortcut
- Provides a dedicated settings window from the menu bar panel, context menu, or `Command + ,`
- Runs in the menu bar without a Dock icon
- Left-click opens the input source panel; right-click opens quick actions
- Supports English, 简体中文, Français, Deutsch, and 日本語
- Supports launch at login and restoring the last lock after restart

## Requirements

- macOS 12.0 Monterey or later
- Launch at login requires macOS 13.0 or later

## Installation

Install from GitHub Releases:

1. Open the [Releases](https://github.com/trah01/inputlock-extend/releases) page.
2. Download the latest `LockInput-1.0.dmg`.
3. Open the DMG and drag `lockinput.app` to `Applications`.
4. Launch LockInput from `Applications`.

The current release is not Apple-notarized. If macOS blocks the first launch, allow it in System Settings > Privacy & Security, or Control-click the app and choose Open.

## Usage

- Left-click the menu bar lock icon to open the main panel
- Right-click the menu bar lock icon to open the quick actions menu
- Click an input method in the list to switch to it and lock it
- Use the Lock / Unlock button to lock the current source or release the lock
- Click Settings at the bottom of the main panel, or press `Command + ,`, to open settings
- Configure the temporary switch shortcut and target input source in Settings; after 5 seconds of idle time, the app restores the selected locked input, or leaves it unchanged while typing continues
- Change the interface language in Settings
- Enable Launch at Login to start the app automatically after login on macOS 13.0+
- Enable Restore Last Lock After Restart to restore the previously locked input source when the app starts again

## Unpushed Changes Summary

- Simplified the menu bar panel to focus on lock state, current/locked inputs, input list, and settings entry
- Added a dedicated settings window accessible through `Command + ,`, the context menu, and the main panel
- Extended the temporary shortcut from fixed ABC switching to any enabled input source, with ABC/US as the automatic fallback
- Added shortcut recording support for Globe, Caps Lock, Shift, and regular key combinations
- Fixed menu bar lock icon sizing so lock state changes no longer shift the popover position
- Updated About, installation, and source links to `trah01/inputlock-extend`

## Run From Source

```bash
git clone https://github.com/trah01/inputlock-extend.git
cd inputlock
open lockinput.xcodeproj
```

Select the `lockinput` scheme in Xcode, then run the app.

## Build a Release Package

If `xcodebuild` points to Command Line Tools, switch to full Xcode:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Build the Release app:

```bash
xcodebuild -project lockinput.xcodeproj \
           -scheme lockinput \
           -configuration Release \
           -derivedDataPath build \
           clean build
```

Create the DMG:

```bash
./scripts/create-dmg.sh
```

The generated file is:

```text
LockInput-1.0.dmg
```

## Project Structure

```text
lockinput/
├── lockinputApp.swift        # App entry point and menu bar setup
├── ContentView.swift         # Main panel UI
├── SettingsView.swift        # Settings window UI
├── InputMethodManager.swift  # Input source discovery, switching, and lock enforcement
├── InputSourceLockState.swift # Lock state model
├── LanguageManager.swift     # Runtime language switching
├── Info.plist                # App metadata
├── Assets.xcassets/          # Icons and assets
└── Resources/
    ├── en.lproj/             # English
    ├── zh-Hans.lproj/        # Simplified Chinese
    ├── fr.lproj/             # French
    ├── de.lproj/             # German
    └── ja.lproj/             # Japanese
```

## Localization

To add a language:

1. Create a new `.lproj` folder under `lockinput/Resources/`.
2. Copy an existing `Localizable.strings` file and translate it.
3. Add the language code to `knownRegions` in `lockinput.xcodeproj/project.pbxproj`.
4. Add the language to the `AppLanguage` enum in `LanguageManager.swift`.

## License

This repository does not currently include a separate `LICENSE` file.
