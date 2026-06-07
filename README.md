# TOTPBar

[简体中文](README.zh-CN.md) | English

TOTPBar is a lightweight macOS menu bar authenticator for local-first TOTP / OTPAuth management.

It is built for users who want a small native app that keeps verification codes local, stays fast in the menu bar, and still provides a full main window for editing, importing, exporting, and configuring developer-friendly HTTP access.

It is maintained as an independent project with a focused product experience, modern Swift/Xcode builds, bilingual UI, and separate Apple Silicon / Intel releases.

## Features

- Native macOS menu bar workflow for fast TOTP access
- Full main window for adding, editing, deleting, sorting, importing, and exporting authenticators
- QR code image scanning for OTPAuth URLs
- Live code preview while adding or editing before saving
- Copy verification codes from the main window or menu bar
- Global fill shortcuts: `Shift+Cmd+[0-9]`
- Local-only storage with no cloud account requirement
- English and Simplified Chinese UI with an in-app language switcher
- Launch at login
- Optional local HTTP API for scripts and developer workflows
- Separate unsigned/ad-hoc builds for Apple Silicon and Intel Macs

## Screenshots

Screenshots are being refreshed for the TOTPBar brand.

## Download

Download the latest build from [GitHub Releases](https://github.com/jerry-pond/TOTPBar/releases).

Release assets are provided separately for:

- Apple Silicon: `TOTPBar-vX.Y.Z-buildN-arm64.zip`
- Intel Mac: `TOTPBar-vX.Y.Z-buildN-x86_64.zip`

Unzip the package for your Mac and move `TOTPBar.app` to `/Applications`.

The release packages are ad-hoc signed and do not use an Apple Developer ID. On first launch, macOS may require opening the app from Finder with right click > Open, or allowing it in System Settings > Privacy & Security.

## Usage

1. Start `TOTPBar.app`.
2. Use the main window to manage authenticators.
3. Use the menu bar item for quick code copying.
4. Use `Shift+Cmd+[0-9]` to fill a verification code directly.

### Main Window

The main window is the primary management surface:

- Select an authenticator from the list to view its current code and OTPAuth URL.
- Click `+` to add a new authenticator manually.
- Click `Scan QR...` to import an OTPAuth URL from a QR code image.
- Click `Edit` to update the selected authenticator's name or OTPAuth URL.
- Drag items in the list to customize ordering.
- Use the Settings tab for import/export, launch-at-login, HTTP port, HTTP auto-start, and language preferences.

### Language

Open `Settings` and choose:

- `System`
- `English`
- `简体中文`

The main window updates immediately. The menu bar dropdown also uses the selected language the next time it opens.

## HTTP API

TOTPBar can expose verification codes through a local HTTP API:

```bash
# Inspect available routes from http://localhost:17304/
code=$(curl 'http://localhost:17304/code/test@example.com')
echo "$code"
```

The HTTP service can be started or stopped from the menu bar. Port and auto-start settings are available in the Settings tab.

## Building

TOTPBar uses Swift Package Manager for dependencies. CocoaPods is not required.

1. Install the latest stable Xcode.
2. Open `TOTPBar.xcodeproj` with Xcode.
3. Let Xcode resolve Swift Package dependencies.
4. Build the `TOTPBar` scheme.

Command-line build example:

```bash
xcodebuild \
  -project TOTPBar.xcodeproj \
  -scheme TOTPBar \
  -configuration Release \
  -destination 'platform=macOS' \
  build
```

## Project Notes

TOTPBar is a local-first macOS app. It stores authenticator data in the user's Application Support directory and does not require an account or cloud sync.

## Resources

- [Swift Package Manager](https://www.swift.org/package-manager/)
- [google-authenticator](https://github.com/google/google-authenticator)
- [swifter](https://github.com/httpswift/swifter)
