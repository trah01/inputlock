# LockInput

既定の README: [简体中文](README.md)

他の言語: [English](README.en.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | 日本語

LockInput は、現在の入力方式を固定する軽量な macOS メニューバーアプリです。文章作成、開発作業、アプリ間の移動中に入力方式が誤って切り替わることを減らします。

## 機能

- 現在の入力方式を固定し、別の入力ソースに切り替わった場合は自動的に戻す
- カスタムショートカットで選択した入力方式へ一時的に切り替え、5 秒間入力が止まっていれば固定した入力方式へ戻す
- Globe、Caps Lock、Shift、通常のキー組み合わせを一時切り替えショートカットとして使用可能
- メニューバーパネル、コンテキストメニュー、または `Command + ,` から設定ウィンドウを開けます
- Dock アイコンを表示せず、メニューバーで動作
- 左クリックで入力ソース一覧を開き、右クリックでクイック操作を開く
- English、简体中文、Français、Deutsch、日本語に対応
- ログイン時の起動と、再起動後の前回ロック復元に対応

## 必要環境

- macOS 12.0 Monterey 以降
- ログイン時に起動する機能は macOS 13.0 以降が必要です

## インストール

GitHub Releases からのインストールを推奨します。

1. [Releases](https://github.com/trah01/inputlock-extend/releases) ページを開きます。
2. 最新の `LockInput-1.0.dmg` をダウンロードします。
3. DMG を開き、`lockinput.app` を `Applications` にドラッグします。
4. `Applications` から LockInput を起動します。

現在のリリースは Apple の公証を受けていません。初回起動時に macOS によりブロックされた場合は、システム設定 > プライバシーとセキュリティで許可するか、Control キーを押しながらアプリをクリックして「開く」を選択してください。

## 使い方

- メニューバーのロックアイコンを左クリック: メインパネルを開く
- メニューバーのロックアイコンを右クリック: クイック操作メニューを開く
- 一覧内の入力方式をクリック: その入力方式に切り替えて固定する
- 固定 / 解除ボタン: 現在の入力ソースを固定、または固定を解除
- メインパネル下部の設定、または `Command + ,` で設定ウィンドウを開きます
- 設定で一時切り替えショートカットと切り替え先入力方式を指定します。5 秒間入力が止まっていれば固定した入力方式へ戻り、入力中ならそのまま維持します
- 設定でインターフェイス言語を変更
- ログイン時に起動を有効化: macOS 13.0 以降でログイン後に自動起動
- 再起動後に前回のロックを復元を有効化: 次回起動時に前回固定した入力方式を復元

## ソースから実行

```bash
git clone https://github.com/trah01/inputlock-extend.git
cd inputlock
open lockinput.xcodeproj
```

Xcode で `lockinput` scheme を選択して実行します。

## リリースパッケージのビルド

`xcodebuild` が Command Line Tools を指している場合は、完全版の Xcode に切り替えます。

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

Release app をビルドします。

```bash
xcodebuild -project lockinput.xcodeproj \
           -scheme lockinput \
           -configuration Release \
           -derivedDataPath build \
           clean build
```

DMG を作成します。

```bash
./scripts/create-dmg.sh
```

生成されるファイル:

```text
LockInput-1.0.dmg
```

## プロジェクト構成

```text
lockinput/
├── lockinputApp.swift        # アプリのエントリーポイントとメニューバー設定
├── ContentView.swift         # メインパネル UI
├── SettingsView.swift        # 設定ウィンドウ UI
├── InputMethodManager.swift  # 入力ソースの検出、切り替え、固定処理
├── InputSourceLockState.swift # 固定状態モデル
├── LanguageManager.swift     # 実行時の言語切り替え
├── Info.plist                # アプリのメタデータ
├── Assets.xcassets/          # アイコンとアセット
└── Resources/
    ├── en.lproj/             # 英語
    ├── zh-Hans.lproj/        # 簡体字中国語
    ├── fr.lproj/             # フランス語
    ├── de.lproj/             # ドイツ語
    └── ja.lproj/             # 日本語
```

## ローカライズ

言語を追加する手順:

1. `lockinput/Resources/` に新しい `.lproj` フォルダを作成します。
2. 既存の `Localizable.strings` をコピーして翻訳します。
3. `lockinput.xcodeproj/project.pbxproj` の `knownRegions` に言語コードを追加します。
4. `LanguageManager.swift` の `AppLanguage` enum に言語を追加します。

## ライセンス

このリポジトリには現在、個別の `LICENSE` ファイルは含まれていません。
