# GFloat

**A floating Google Gemini window for macOS — always one hotkey away.**

<!-- ![GFloat Demo](assets/demo.gif) -->

[한국어](README.ko.md)

## Features

- **Global hotkey toggle** — Show/hide with `Cmd+Shift+G` (customizable)
- **Floating window** — Stays on top of all apps
- **Persistent chat state** — Your conversation is preserved across show/hide
- **Drag handle** — Easily reposition the window anywhere on screen
- **Configurable window size** — Set your preferred dimensions (default 800×800)
- **Auto-hide** — Optionally hide the window when switching to another app
- **Launch at login** — Start GFloat automatically when you log in
- **Menubar-only** — No dock icon clutter, lives quietly in your menu bar

## Installation

### Download

> Prebuilt binaries will be available on the [GitHub Releases](../../releases) page.

### Build from Source

```bash
git clone https://github.com/kcd71461/gfloat.git
cd gfloat
bash scripts/install.sh
```

This builds the app, installs it to `/Applications`, and launches it automatically.

To build without installing:

```bash
bash scripts/bundle.sh
open build/GFloat.app
```

### Requirements

- macOS 14 (Sonoma) or later
- Xcode Command Line Tools (`xcode-select --install`)
- Accessibility permission (prompted on first launch)

## Usage

### First Launch

On first launch, GFloat will guide you through an onboarding flow to grant the required **Accessibility permission**. This is needed for the global hotkey to work system-wide.

### Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Cmd+Shift+G` | Toggle GFloat window |
| `Cmd+,` | Open Preferences |
| `ESC` `ESC` | Hide window (double-press) |
| `Cmd+Q` | Quit GFloat |

### Menubar Menu

Click the GFloat icon in the menu bar to access:

- **Show/Hide** — Toggle the floating window
- **Preferences…** — Open the preferences window
- **Launch at Login** — Toggle auto-start on login
- **Quit GFloat** — Exit the application

<!-- ![Preferences Window](assets/preferences.png) -->

## Configuration

All settings are accessible via **Preferences** (`Cmd+,`):

| Setting | Default | Description |
|---|---|---|
| Hotkey | `Cmd+Shift+G` | Global shortcut to toggle the window |
| Window width | 800 | Window width in pixels (min 320) |
| Window height | 800 | Window height in pixels (min 400) |
| Hide on deactivate | On | Auto-hide when another app gains focus |
| Launch at login | Off | Start GFloat when you log in |

## Development

### Project Structure

```
gfloat/
├── Sources/GFloat/
│   ├── main.swift              # App entry point
│   ├── AppDelegate.swift       # App lifecycle & menubar setup
│   ├── FloatingWindow.swift    # Floating panel window
│   ├── WebViewController.swift # WebView loading Google Gemini
│   ├── HotkeyManager.swift     # Global hotkey registration
│   ├── Config.swift             # UserDefaults-backed configuration
│   ├── OnboardingWindow.swift   # First-launch onboarding flow
│   └── PreferencesWindow.swift  # Preferences UI
├── Resources/
│   ├── Info.plist               # App bundle metadata
│   ├── AppIcon.icns             # Application icon
│   └── MenuBarIcon/             # Menu bar icon assets
├── scripts/
│   ├── bundle.sh                # Build & create .app bundle
│   ├── install.sh               # Build, install to /Applications & launch
│   ├── generate-icons.swift     # Icon generation utility
│   └── debug-window.swift       # Window debugging helper
├── docs/                        # Documentation
└── Package.swift                # Swift Package Manager manifest
```

### Key Components

| Component | Description |
|---|---|
| `AppDelegate` | Manages app lifecycle, menubar, and coordinates all components |
| `FloatingWindow` | `NSPanel` subclass that stays on top and supports drag repositioning |
| `WebViewController` | Hosts a `WKWebView` pointed at Google Gemini |
| `HotkeyManager` | Registers/unregisters Carbon-based global hotkeys |
| `Config` | Singleton wrapping `UserDefaults` for all app settings |
| `OnboardingWindow` | Guides users through Accessibility permission setup |
| `PreferencesWindow` | UI for customizing hotkey, window size, and behavior |

### Build Commands

```bash
# Debug build
swift build

# Run directly
swift run GFloat

# Release build + app bundle
bash scripts/bundle.sh

# Build, install to /Applications & launch
bash scripts/install.sh
```

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Disclaimer

This project is not affiliated with, endorsed by, or associated with Google LLC. Google and Gemini are trademarks of Google LLC.
