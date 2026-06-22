# LockInput

README par défaut : [简体中文](README.md)

Autres langues : [English](README.en.md) | Français | [Deutsch](README.de.md) | [日本語](README.ja.md)

LockInput est une application légère pour la barre de menus de macOS. Elle verrouille la méthode de saisie active afin de limiter les changements accidentels lors de la rédaction, du développement ou du passage d'une application à l'autre.

## Fonctionnalités

- Verrouille la méthode de saisie active et la rétablit si une autre source devient active
- Utilise automatiquement une disposition ABC/ASCII temporaire dans les champs de saisie sécurisée macOS, comme les mots de passe
- Prend en charge un raccourci personnalisé pour passer temporairement à ABC et rétablir la source verrouillée après 15 s d'inactivité
- Fonctionne dans la barre de menus, sans icône dans le Dock
- Clic gauche pour ouvrir le panneau des méthodes de saisie ; clic droit pour les actions rapides
- Prend en charge English, 简体中文, Français, Deutsch et 日本語
- Prend en charge le lancement à l'ouverture de session sous macOS 13.0 ou version ultérieure

## Prérequis

- macOS 12.0 Monterey ou version ultérieure
- Le lancement à l'ouverture de session nécessite macOS 13.0 ou version ultérieure

## Installation

Installation recommandée depuis GitHub Releases :

1. Ouvrez la page [Releases](https://github.com/bigccc/inputlock/releases).
2. Téléchargez le dernier fichier `LockInput-1.0.dmg`.
3. Ouvrez le DMG et faites glisser `lockinput.app` vers `Applications`.
4. Lancez LockInput depuis `Applications`.

La version actuelle n'est pas notariée par Apple. Si macOS bloque le premier lancement, autorisez l'application dans Réglages Système > Confidentialité et sécurité, ou cliquez sur l'application avec Control puis choisissez Ouvrir.

## Utilisation

- Clic gauche sur l'icône de verrouillage dans la barre de menus : ouvrir le panneau principal
- Clic droit sur l'icône : ouvrir le menu d'actions rapides
- Clic sur une méthode de saisie : basculer vers cette méthode et la verrouiller
- Bouton Verrouiller / Déverrouiller : verrouiller la source active ou libérer le verrou
- Dans les champs de saisie sécurisée comme les mots de passe, l'app passe automatiquement en ABC/ASCII temporaire ; la source verrouillée est rétablie après la sortie de la saisie sécurisée
- Définissez le raccourci ABC temporaire en bas du panneau, puis utilisez-le pour passer à ABC ; après 15 s, l'app rétablit la source verrouillée si la saisie s'est arrêtée, sinon elle ne change rien
- Menu de langue en bas du panneau : changer la langue de l'interface
- Option de lancement à l'ouverture de session : démarrer l'application automatiquement sous macOS 13.0+

## Exécuter depuis le code source

```bash
git clone https://github.com/bigccc/inputlock.git
cd inputlock
open lockinput.xcodeproj
```

Sélectionnez le scheme `lockinput` dans Xcode, puis lancez l'application.

## Construire un paquet de publication

Si `xcodebuild` pointe vers Command Line Tools, basculez vers Xcode complet :

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Construisez l'application Release :

```bash
xcodebuild -project lockinput.xcodeproj \
           -scheme lockinput \
           -configuration Release \
           -derivedDataPath build \
           clean build
```

Créez le DMG :

```bash
./scripts/create-dmg.sh
```

Le fichier généré est :

```text
LockInput-1.0.dmg
```

## Structure du projet

```text
lockinput/
├── lockinputApp.swift        # Point d'entrée et barre de menus
├── ContentView.swift         # Interface du panneau principal
├── InputMethodManager.swift  # Détection, changement et verrouillage des sources de saisie
├── InputSourceLockState.swift # Modèle d'état du verrouillage
├── LanguageManager.swift     # Changement de langue à l'exécution
├── Info.plist                # Métadonnées de l'application
├── Assets.xcassets/          # Icônes et ressources
└── Resources/
    ├── en.lproj/             # English
    ├── zh-Hans.lproj/        # Chinois simplifié
    ├── fr.lproj/             # Français
    ├── de.lproj/             # Allemand
    └── ja.lproj/             # Japonais
```

## Localisation

Pour ajouter une langue :

1. Créez un nouveau dossier `.lproj` dans `lockinput/Resources/`.
2. Copiez un fichier `Localizable.strings` existant et traduisez-le.
3. Ajoutez le code de langue à `knownRegions` dans `lockinput.xcodeproj/project.pbxproj`.
4. Ajoutez la langue à l'énumération `AppLanguage` dans `LanguageManager.swift`.

## Licence

Ce dépôt ne contient pas actuellement de fichier `LICENSE` séparé.
