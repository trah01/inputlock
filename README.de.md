# LockInput

Standard-README: [简体中文](README.md)

Weitere Sprachen: [English](README.en.md) | [Français](README.fr.md) | Deutsch | [日本語](README.ja.md)

LockInput ist eine schlanke macOS-Menüleisten-App. Sie sperrt die aktuelle Eingabemethode und verhindert so versehentliche Wechsel beim Schreiben, Programmieren oder Wechseln zwischen Apps.

## Funktionen

- Sperrt die aktuelle Eingabemethode und stellt sie wieder her, wenn eine andere Quelle aktiv wird
- Verwendet in macOS-Sicherheitseingabefeldern wie Passwortfeldern automatisch temporär ein ABC/ASCII-Layout
- Unterstützt einen eigenen Kurzbefehl, der temporär zu ABC wechselt und nach 15 s Leerlauf die gesperrte Eingabe wiederherstellt
- Läuft in der Menüleiste, ohne Dock-Symbol
- Linksklick öffnet die Eingabequellenliste; Rechtsklick öffnet Schnellaktionen
- Unterstützt English, 简体中文, Français, Deutsch und 日本語
- Unterstützt Start bei der Anmeldung unter macOS 13.0 oder neuer

## Voraussetzungen

- macOS 12.0 Monterey oder neuer
- Start bei der Anmeldung erfordert macOS 13.0 oder neuer

## Installation

Empfohlene Installation über GitHub Releases:

1. Öffnen Sie die Seite [Releases](https://github.com/bigccc/inputlock/releases).
2. Laden Sie die aktuelle Datei `LockInput-1.0.dmg` herunter.
3. Öffnen Sie die DMG-Datei und ziehen Sie `lockinput.app` in `Applications`.
4. Starten Sie LockInput aus `Applications`.

Die aktuelle Veröffentlichung ist nicht von Apple notarisiert. Wenn macOS den ersten Start blockiert, erlauben Sie die App unter Systemeinstellungen > Datenschutz & Sicherheit, oder klicken Sie mit gedrückter Control-Taste auf die App und wählen Sie Öffnen.

## Verwendung

- Linksklick auf das Schloss-Symbol in der Menüleiste: Hauptfenster öffnen
- Rechtsklick auf das Schloss-Symbol: Schnellaktionsmenü öffnen
- Klick auf eine Eingabemethode: zu dieser Methode wechseln und sie sperren
- Schaltfläche Sperren / Entsperren: aktuelle Quelle sperren oder Sperre aufheben
- In Sicherheitseingabefeldern wie Passwortfeldern wechselt die App automatisch temporär zu ABC/ASCII; nach dem Verlassen der Sicherheitseingabe wird die gesperrte Quelle wiederhergestellt
- Unten den temporären ABC-Kurzbefehl festlegen und drücken, um zu ABC zu wechseln; nach 15 s stellt die App die gesperrte Eingabe wieder her, wenn die Eingabe gestoppt wurde, andernfalls bleibt sie unverändert
- Sprachmenü unten: Sprache der Oberfläche wechseln
- Start bei der Anmeldung aktivieren: App unter macOS 13.0+ automatisch nach der Anmeldung starten

## Aus dem Quellcode ausführen

```bash
git clone https://github.com/bigccc/inputlock.git
cd inputlock
open lockinput.xcodeproj
```

Wählen Sie in Xcode das Scheme `lockinput` aus und starten Sie die App.

## Release-Paket bauen

Wenn `xcodebuild` auf Command Line Tools zeigt, wechseln Sie zu vollständigem Xcode:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Release-App bauen:

```bash
xcodebuild -project lockinput.xcodeproj \
           -scheme lockinput \
           -configuration Release \
           -derivedDataPath build \
           clean build
```

DMG erstellen:

```bash
./scripts/create-dmg.sh
```

Die erzeugte Datei ist:

```text
LockInput-1.0.dmg
```

## Projektstruktur

```text
lockinput/
├── lockinputApp.swift        # App-Einstieg und Menüleistenlogik
├── ContentView.swift         # Hauptoberfläche
├── InputMethodManager.swift  # Erkennung, Wechsel und Sperrung der Eingabequellen
├── InputSourceLockState.swift # Modell für den Sperrzustand
├── LanguageManager.swift     # Sprachwechsel zur Laufzeit
├── Info.plist                # App-Metadaten
├── Assets.xcassets/          # Symbole und Ressourcen
└── Resources/
    ├── en.lproj/             # Englisch
    ├── zh-Hans.lproj/        # Vereinfachtes Chinesisch
    ├── fr.lproj/             # Französisch
    ├── de.lproj/             # Deutsch
    └── ja.lproj/             # Japanisch
```

## Lokalisierung

So fügen Sie eine Sprache hinzu:

1. Erstellen Sie unter `lockinput/Resources/` einen neuen `.lproj`-Ordner.
2. Kopieren Sie eine vorhandene `Localizable.strings`-Datei und übersetzen Sie sie.
3. Fügen Sie den Sprachcode zu `knownRegions` in `lockinput.xcodeproj/project.pbxproj` hinzu.
4. Fügen Sie die Sprache zur Enumeration `AppLanguage` in `LanguageManager.swift` hinzu.

## Lizenz

Dieses Repository enthält derzeit keine separate `LICENSE`-Datei.
