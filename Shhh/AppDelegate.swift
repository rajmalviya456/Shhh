import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem?
    private(set) var micState: MicState?
    private(set) var hotKeyManager: HotKeyManager?
    var popover: NSPopover?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSLog("🚀 App launched, initializing Shhh...")

        // Own the state objects so initialization is not dependent on a SwiftUI window appearing
        let micState = MicState()
        let hotKeyManager = HotKeyManager.shared
        self.micState = micState
        self.hotKeyManager = hotKeyManager

        // Check accessibility permission
        checkAccessibilityPermission()

        // Connect hotkey manager to mic state
        hotKeyManager.connect(to: micState)

        // Setup status item
        setupStatusItem(micState: micState, hotKeyManager: hotKeyManager)

        // Observe mic state changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("MicStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateIcon()
        }

        NSLog("✅ Shhh initialized successfully")
        NSLog("📍 Look for the microphone icon in your menu bar (top-right of screen)")
    }

    private func checkAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if accessEnabled {
            NSLog("✅ Accessibility permission granted")
        } else {
            NSLog("⚠️ Accessibility permission required for hotkeys!")
            NSLog("   Please grant permission in System Settings → Privacy & Security → Accessibility")
        }
    }

    private func setupStatusItem(micState: MicState, hotKeyManager: HotKeyManager) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            let icon = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Microphone")
            icon?.isTemplate = true
            button.image = icon

            // Primary action (left-click) - toggle
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        updateIcon()
    }

    @objc private func handleClick() {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showMenu()
        } else {
            // Left click - toggle
            micState?.toggleMic()
            updateIcon()
        }
    }

    @objc func updateIcon() {
        guard let button = statusItem?.button,
              let micState = micState else { return }

        let opacity = micState.inputVolume == 0 ? 0.3 : 0.3 + (micState.inputVolume / 100.0) * 0.7
        button.alphaValue = opacity
    }

    private func showMenu() {
        guard let micState = micState,
              let hotKeyManager = hotKeyManager else { return }

        let popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuContentView(micState: micState, hotKeyManager: hotKeyManager)
        )

        if let button = statusItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }

        self.popover = popover
    }
}
