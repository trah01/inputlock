# LockInput

Default README: [简体中文](README.md)

Other languages: English | [Français](README.fr.md) | [Deutsch](README.de.md) | [日本語](README.ja.md)

LockInput is a lightweight macOS menu bar app that locks the current input method and helps prevent accidental input source switching while writing, coding, or moving between apps.

## Features

- Locks the current input method and switches back if another source becomes active
- Automatically uses a temporary ABC/ASCII layout in macOS secure text entry fields such as password inputs
- Supports a custom shortcut that temporarily switches to ABC and restores the locked input when idle after 15 seconds
- Runs in the menu bar without a Dock icon
- Left-click opens the input source panel; right-click opens quick actions
- Supports English, 简体中文, Français, Deutsch, and 日本語
- Supports launch at login on macOS 13.0 or later

## Requirements

- macOS 12.0 Monterey or later
- Launch at login requires macOS 13.0 or later

## Installation

Install from GitHub Releases:

1. Open the [Releases](https://github.com/bigccc/inputlock/releases) page.
2. Download the latest `LockInput-1.0.dmg`.
3. Open the DMG and drag `lockinput.app` to `Applications`.
4. Launch LockInput from `Applications`.

The current release is not Apple-notarized. If macOS blocks the first launch, allow it in System Settings > Privacy & Security, or Control-click the app and choose Open.

## Usage

- Left-click the menu bar lock icon to open the main panel
- Right-click the menu bar lock icon to open the quick actions menu
- Click an input method in the list to switch to it and lock it
- Use the Lock / Unlock button to lock the current source or release the lock
- In secure text entry fields such as password inputs, the app temporarily switches to ABC/ASCII automatically; the locked source is restored after leaving secure entry
- Set Temporary ABC Shortcut at the bottom, then press it to switch to ABC; after 15 seconds, the app restores the selected locked input if typing has stopped, or leaves it unchanged while typing continues
- Change the interface language from the language menu at the bottom
- Enable Launch at Login to start the app automatically after login on macOS 13.0+

## Run From Source

```bash
git clone https://github.com/bigccc/inputlock.git
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
