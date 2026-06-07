# TOTPBar

简体中文 | [English](README.md)

TOTPBar 是一个轻量的 macOS 菜单栏 TOTP / OTPAuth 验证码管理工具。

它面向希望验证码保持本地、菜单栏快速可用、同时又需要完整主窗口来编辑、导入、导出和配置 HTTP API 的用户。

TOTPBar 是一个独立维护的项目，拥有聚焦的产品体验、现代 Swift/Xcode 构建、双语界面，以及 Apple Silicon / Intel 分架构发布包。

## 功能

- 原生 macOS 菜单栏验证码访问
- 完整主窗口，支持添加、编辑、删除、排序、导入和导出认证信息
- 从二维码图片识别 OTPAuth URL
- 添加或编辑时可在保存前实时预览验证码
- 可从主窗口或菜单栏复制验证码
- 全局填充快捷键：`Shift+Cmd+[0-9]`
- 本地优先存储，不需要云账号
- 支持英文和简体中文界面，并可在应用设置中切换语言
- 支持开机启动
- 可选本地 HTTP API，方便脚本和开发者工作流读取验证码
- 分别提供 Apple Silicon 和 Intel Mac 的 unsigned/ad-hoc 构建

## 截图

截图将按 TOTPBar 新品牌重新整理。

## 下载

请从 [GitHub Releases](https://github.com/jerry-pond/TOTPBar/releases) 下载最新版本。

发布附件按架构分别提供：

- Apple Silicon：`TOTPBar-vX.Y.Z-buildN-arm64.zip`
- Intel Mac：`TOTPBar-vX.Y.Z-buildN-x86_64.zip`

解压适合你 Mac 架构的包，然后将 `TOTPBar.app` 移动到 `/Applications`。

这些发布包使用 ad-hoc 签名，没有 Apple Developer ID。首次启动时，macOS 可能要求你在 Finder 中右键选择“打开”，或在“系统设置 > 隐私与安全性”中允许打开。

## 使用

1. 启动 `TOTPBar.app`。
2. 使用主窗口管理认证信息。
3. 使用菜单栏入口快速复制验证码。
4. 使用 `Shift+Cmd+[0-9]` 直接填入验证码。

### 主窗口

主窗口是主要管理界面：

- 从左侧列表选择认证信息，查看当前验证码和 OTPAuth URL。
- 点击 `+` 手动添加新的认证信息。
- 点击 `扫描二维码...` 从二维码图片导入 OTPAuth URL。
- 点击 `编辑` 修改选中认证信息的名称或 OTPAuth URL。
- 拖拽左侧列表条目来自定义排序。
- 在设置页中使用导入、导出、开机启动、HTTP 端口、HTTP 自动启动和语言设置。

### 语言

打开 `设置`，可以选择：

- `跟随系统`
- `English`
- `简体中文`

主窗口会立即更新语言。菜单栏下拉菜单会在下次打开时使用新的语言。

## HTTP API

TOTPBar 可以通过本地 HTTP API 暴露验证码：

```bash
# 可通过 http://localhost:17304/ 查看可用路由
code=$(curl 'http://localhost:17304/code/test@example.com')
echo "$code"
```

HTTP 服务可以从菜单栏开启或停止。端口和自动启动设置在设置页中配置。

## 构建

TOTPBar 使用 Swift Package Manager 管理依赖，不需要 CocoaPods。

1. 安装最新稳定版 Xcode。
2. 使用 Xcode 打开 `TOTPBar.xcodeproj`。
3. 等待 Xcode 自动解析 Swift Package 依赖。
4. 构建 `TOTPBar` scheme。

命令行构建示例：

```bash
xcodebuild \
  -project TOTPBar.xcodeproj \
  -scheme TOTPBar \
  -configuration Release \
  -destination 'platform=macOS' \
  build
```

## 项目说明

TOTPBar 是本地优先的 macOS 应用。认证信息存储在用户的 Application Support 目录中，不需要账号或云同步。

## 资源

- [Swift Package Manager](https://www.swift.org/package-manager/)
- [google-authenticator](https://github.com/google/google-authenticator)
- [swifter](https://github.com/httpswift/swifter)
