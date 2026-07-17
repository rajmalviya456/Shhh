# Shhh 🤫

> A minimalist macOS menu bar app for instant microphone control

[![Swift](https://img.shields.io/badge/Swift-5-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2026.2+-blue.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview

**Shhh** is a lightweight, native macOS menu bar application that gives you instant control over your microphone. With a single click or keyboard shortcut, you can mute/unmute your mic, adjust volume, and monitor audio levels—all from your menu bar.

Perfect for:
- 🎙️ Podcast recording
- 💼 Video conferences
- 🎮 Gaming
- 🎵 Music production
- 📞 Voice calls

## Features

### 🎯 Core Features
- **One-Click Mute/Unmute** - Left-click the menu bar icon to toggle microphone
- **Global Hotkey** - Customizable keyboard shortcut (default: `⌃⌥⌘M`)
- **Volume Control** - Smooth slider for precise volume adjustment (0-100%)
- **Visual Feedback** - Menu bar icon opacity reflects current volume level
- **Start at Login** - Optional auto-start on system boot

### 🎨 Design
- **Native macOS UI** - System-standard menus and controls
- **Menu Bar Only** - No dock icon, stays out of your way
- **Dark Mode Support** - Seamless integration with system appearance
- **Minimal Resource Usage** - Lightweight and efficient

### 🔒 Privacy & Security
- **Sandboxed** - Runs in macOS App Sandbox for security
- **No Network Access** - All processing happens locally
- **No Data Collection** - Your privacy is paramount
- **Open Source** - Fully transparent codebase

## Installation

### Requirements
- macOS 26.2 (Tahoe) or later

### Download

- [GitHub Releases](https://github.com/rajmalviya456/Shhh/releases/latest) — free
- [Gumroad](https://rajmalviya456.gumroad.com/l/shhh) — same app, pay what you want ($0 works)

The prebuilt zip is not notarized yet: on first launch, right-click
Shhh.app and choose **Open**.

### Build from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/rajmalviya456/Shhh.git
   cd Shhh
   ```

2. **Open in Xcode**
   ```bash
   open Shhh.xcodeproj
   ```

3. **Build and Run**
   - Select the `Shhh` scheme
   - Press `⌘R` to build and run

## Usage

### Quick Start

1. **Launch Shhh** - The microphone icon appears in your menu bar
2. **Left-click** - Toggle mute/unmute instantly
3. **Right-click** - Open the control menu

### Keyboard Shortcuts

- **Toggle Mute** - `⌃⌥⌘M` (Control + Option + Command + M) - Customizable
- **Quit App** - `⌘Q` (Command + Q)

### Customizing Hotkey

1. Right-click menu bar icon
2. Select "Change Shortcut"
3. Press your desired key combination
4. Click "Save" or press Enter

## Architecture

### Modern Swift 6 Implementation

**Shhh** is built with the latest Swift 6 features and modern macOS development practices:

- ✅ **Swift Concurrency** - `async/await` with `@MainActor` default isolation
- ✅ **Event-Driven Audio** - CoreAudio HAL property listeners, no polling
- ✅ **Structured Logging** - OSLog for production-grade logging
- ✅ **Typed Errors** - Comprehensive error handling
- ✅ **SwiftUI** - Modern declarative UI
- ✅ **Combine** - Reactive state management

### Project Structure

```
Shhh/
├── Shhh/
│   ├── ShhhApp.swift            # App entry point
│   ├── AppDelegate.swift        # Menu bar setup
│   ├── MicController.swift      # Microphone control (CoreAudio HAL)
│   ├── MicState.swift           # Reactive state management
│   ├── HotKeyManager.swift      # Global hotkey handling
│   ├── LoginItemManager.swift   # Start at login
│   └── Views/
│       ├── MenuContentView.swift      # Main menu UI
│       └── HotkeyRecorderView.swift   # Hotkey configuration
└── ShhhTests/                   # Unit tests
```

### Key Components

#### MicController
- Controls the default input device via the CoreAudio HAL
- Handles volume get/set operations
- Manages mute/unmute with volume restoration
- Event-driven change notifications via `AudioObjectAddPropertyListener`
- Thread-safe with `@MainActor` isolation

#### MicState
- Observable state management with `@Published` properties
- Updates instantly on external volume changes (no polling)
- Error logging via OSLog

#### HotKeyManager
- Global keyboard shortcut registration
- Persistent hotkey preferences
- Singleton pattern for app-wide access
- Window management for hotkey configuration

## Development

### Building

```bash
# Clean build
xcodebuild -project Shhh.xcodeproj -scheme Shhh clean build

# Run tests
xcodebuild test -project Shhh.xcodeproj -scheme Shhh

# Build for release
xcodebuild -project Shhh.xcodeproj -scheme Shhh -configuration Release build
```

### Dependencies

- [HotKey](https://github.com/soffes/HotKey) - Global keyboard shortcut handling

### Code Quality

- ✅ Approachable concurrency with `@MainActor` default isolation
- ✅ Comprehensive error handling
- ✅ OSLog structured logging
- ✅ Unit test coverage for core components

## Troubleshooting

### Hotkey Not Working
1. Check **System Settings** → **Keyboard** → **Keyboard Shortcuts**
2. Ensure no conflicts with existing shortcuts
3. Try a different key combination

### App Not Starting at Login
1. Open **System Settings** → **General** → **Login Items**
2. Verify **Shhh** is in the list
3. Toggle "Start at Login" in the app menu

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development Guidelines
- Follow Swift API Design Guidelines
- Maintain Swift 6 concurrency safety
- Add tests for new features
- Update documentation

## License

MIT License - See [LICENSE](LICENSE) file for details

## Acknowledgments

- Built with [HotKey](https://github.com/soffes/HotKey) by Sam Soffes
- Inspired by the need for simple, reliable microphone control on macOS

---

**Made with ❤️ for the macOS community**
