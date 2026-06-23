# LockInput

默认语言：简体中文

其他语言： [English](README.en.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [日本語](README.ja.md)

LockInput 是一个轻量级 macOS 菜单栏应用，用于锁定当前输入法，减少在写作、编程或跨应用切换时误触切换输入法的问题。

## 功能

- 锁定当前输入法，并在输入法被系统或应用切走后自动切回
- 支持自定义快捷键临时切到指定输入法，空闲 5 秒后恢复锁定输入法
- 支持 Globe、Caps Lock、Shift 或常规组合键作为临时切换快捷键
- 提供独立设置窗口，可通过状态栏面板、右键菜单或 `Command + ,` 打开
- 在菜单栏运行，不显示 Dock 图标
- 左键打开输入法列表，右键打开快速菜单
- 支持 English、简体中文、Français、Deutsch、日本語
- 支持开机启动设置，以及重启后恢复上次锁定

## 系统要求

- macOS 12.0 Monterey 或更高版本
- 开机启动功能需要 macOS 13.0 或更高版本

## 安装

推荐从 GitHub Release 安装：

1. 打开 [Releases](https://github.com/trah01/inputlock-extend/releases) 页面。
2. 下载最新的 `LockInput-1.0.dmg`。
3. 打开 DMG，把 `lockinput.app` 拖到 `Applications` 文件夹。
4. 从 `Applications` 启动 LockInput。

当前发布包未经过 Apple 公证。如果 macOS 首次启动时提示无法打开，请在“系统设置 > 隐私与安全性”中允许打开，或按住 Control 点击应用后选择“打开”。

## 使用

- 左键点击菜单栏锁图标：打开主面板
- 右键点击菜单栏锁图标：打开快速操作菜单
- 点击列表中的输入法：切换到该输入法并锁定
- 点击“锁定 / 解锁”：锁定当前输入法或解除锁定
- 点击主面板底部“设置”，或按 `Command + ,` 打开设置窗口
- 在设置中配置“临时切换快捷键”和目标输入法；如果 5 秒内没有继续输入，会恢复到选定的锁定输入法，如果仍在输入则暂不切回
- 在设置中切换界面语言
- 打开“开机启动”后，应用会在登录时自动启动（macOS 13.0+）
- 打开“重启后恢复上次锁定”后，应用重新启动时会恢复上一次锁定的输入法

## 未推送变更摘要

- 精简状态栏主面板，只保留锁定状态、当前/锁定输入法、输入法列表和设置入口
- 新增独立设置窗口，支持 `Command + ,`、右键菜单和主面板入口打开
- 临时切换快捷键从固定 ABC 扩展为可选择任意已启用输入法，未指定时自动选择 ABC/US
- 快捷键录制支持 Globe、Caps Lock、Shift 以及常规组合键
- 固定菜单栏锁图标尺寸，避免锁定状态变化导致弹窗位置位移
- 关于链接、安装链接和源码地址已更新为 `trah01/inputlock-extend`

## 从源码运行

```bash
git clone https://github.com/trah01/inputlock-extend.git
cd inputlock
open lockinput.xcodeproj
```

在 Xcode 中选择 `lockinput` scheme 后运行。

## 构建发布包

如果 `xcodebuild` 当前指向 Command Line Tools，需要切换到完整 Xcode：

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

构建 Release app：

```bash
xcodebuild -project lockinput.xcodeproj \
           -scheme lockinput \
           -configuration Release \
           -derivedDataPath build \
           clean build
```

生成 DMG：

```bash
./scripts/create-dmg.sh
```

生成的文件为：

```text
LockInput-1.0.dmg
```

## 项目结构

```text
lockinput/
├── lockinputApp.swift        # 应用入口与菜单栏
├── ContentView.swift         # 主面板 UI
├── SettingsView.swift        # 设置窗口 UI
├── InputMethodManager.swift  # 输入法读取、切换和锁定逻辑
├── InputSourceLockState.swift # 锁定状态模型
├── LanguageManager.swift     # 运行时语言切换
├── Info.plist                # 应用元数据
├── Assets.xcassets/          # 图标和资源
└── Resources/
    ├── en.lproj/             # English
    ├── zh-Hans.lproj/        # 简体中文
    ├── fr.lproj/             # Français
    ├── de.lproj/             # Deutsch
    └── ja.lproj/             # 日本語
```

## 本地化

新增语言时：

1. 在 `lockinput/Resources/` 下创建新的 `.lproj` 目录。
2. 复制现有 `Localizable.strings` 并翻译。
3. 在 `lockinput.xcodeproj/project.pbxproj` 的 `knownRegions` 中加入语言代码。
4. 在 `LanguageManager.swift` 的 `AppLanguage` 中加入对应枚举值。

## 许可证

当前仓库尚未包含单独的 `LICENSE` 文件。
