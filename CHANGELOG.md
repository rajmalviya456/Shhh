# Changelog

All notable changes to Shhh will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-19

### Added
- **Core Microphone Control**
  - One-click mute/unmute from menu bar icon
  - Smooth volume control slider (0-100%)
  - Real-time volume monitoring with 500ms refresh rate
  - Visual feedback via menu bar icon opacity reflecting volume level
  - Volume restoration when unmuting

- **Global Hotkey System**
  - Customizable keyboard shortcut for mute/unmute toggle
  - Default hotkey: `⌃⌥⌘M` (Control + Option + Command + M)
  - Persistent hotkey preferences across app restarts
  - Dedicated hotkey configuration UI with visual recorder
  - Conflict detection and validation

- **Menu Bar Integration**
  - Native macOS menu bar presence (no dock icon)
  - Left-click to toggle mute/unmute
  - Right-click to access full control menu
  - Dynamic icon updates based on microphone state
  - Dark mode support with system appearance integration

- **Start at Login**
  - Optional auto-start on system boot
  - Login item management via macOS ServiceManagement framework
  - Toggle option in menu bar menu

- **User Interface**
  - SwiftUI-based modern interface
  - Menu content view with volume slider
  - Hotkey recorder view for shortcut customization
  - Menu bar icon view with opacity-based volume indication
  - Native macOS controls and styling

- **Architecture & Code Quality**
  - Swift 6 with strict concurrency checking
  - Full `async/await` and actor isolation support
  - `@MainActor` isolation for thread-safe UI updates
  - Sendable conformance for safe concurrent data access
  - Structured logging with OSLog
  - Comprehensive error handling with typed errors
  - Reactive state management using Combine framework

- **Core Components**
  - `MicController`: AppleScript-based microphone control
  - `MicState`: Observable state management with `@Published` properties
  - `HotKeyManager`: Global keyboard shortcut registration and management
  - `LoginItemManager`: Start at login functionality
  - `AppDelegate`: Menu bar setup and lifecycle management

- **Testing**
  - Unit tests for `HotKeyManager`
  - Unit tests for `MicController`
  - Unit tests for `MicState`
  - Zero compiler warnings
  - Comprehensive test coverage for core components

- **Privacy & Security**
  - App Sandbox enabled for enhanced security
  - Hardened runtime protection
  - No network access
  - No data collection or telemetry
  - Local-only processing
  - Microphone permission handling

- **Dependencies**
  - HotKey library for global keyboard shortcut handling

- **Documentation**
  - Comprehensive README with feature overview
  - Architecture documentation
  - Installation and build instructions
  - Usage guide and troubleshooting
  - Contributing guidelines

### Technical Details
- **Platform**: macOS 26.2 (Sequoia) or later
- **Architecture**: Universal (Apple Silicon + Intel)
- **Language**: Swift 6.0
- **UI Framework**: SwiftUI
- **State Management**: Combine
- **Build System**: Xcode project
- **Bundle ID**: com.sharabi.rj.Shhh
- **Version**: 1.0 (Build 1)

### Initial Release Notes
This is the first public release of Shhh, a minimalist macOS menu bar app for instant microphone control. The app provides essential microphone management features with a focus on simplicity, privacy, and native macOS integration.

---

## [Unreleased]

### Planned Features
- [ ] Audio level visualization
- [ ] Multiple microphone device support
- [ ] Preset volume levels
- [ ] Notification center integration
- [ ] Accessibility improvements
- [ ] Localization support

---

[1.0.0]: https://github.com/yourusername/Shhh/releases/tag/v1.0.0
