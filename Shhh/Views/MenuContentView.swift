import SwiftUI
import OSLog

/// The main menu bar menu content view
struct MenuContentView: View {

    // MARK: - Observed Objects

    @ObservedObject var micState: MicState
    @ObservedObject var hotKeyManager: HotKeyManager

    // MARK: - State

    @State private var loginItemEnabled: Bool = LoginItemManager.isEnabled
    @State private var loginItemNeedsApproval: Bool = LoginItemManager.requiresApproval

    // MARK: - Static Properties

    /// Singleton window manager to prevent multiple windows
    private static let windowManager = HotkeyWindowManager()

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Volume status with icon
            HStack(spacing: 12) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 16))
                    .opacity(volumeOpacity)
                    .foregroundColor(.primary)

                Text("Mic Volume: \(Int(micState.inputVolume))%")
                    .font(.system(size: 13, weight: .medium))

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Volume slider
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { micState.inputVolume },
                        set: { micState.setVolume($0) }
                    ),
                    in: 0...100
                )
                .controlSize(.regular)
                .padding(.horizontal, 20)

                HStack {
                    Text("0%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("100%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 12)

            Divider()

            // Quick toggle
            MenuButton(
                icon: micState.isSilent ? "mic.slash.fill" : "mic.fill",
                title: micState.isSilent ? "Unmute Microphone" : "Mute Microphone",
                shortcut: hotKeyManager.currentHotKeyDescription,
                action: { micState.toggleMic() }
            )

            Divider()

            // Hotkey settings
            MenuButton(
                icon: "keyboard",
                title: "Change Shortcut",
                action: { showHotkeyRecorder() }
            )

            Divider()

            // Start at login with checkmark
            MenuButton(
                icon: loginItemNeedsApproval ? "exclamationmark.circle" : "power",
                title: loginItemNeedsApproval ? "Approve in System Settings…" : "Start at Login",
                showCheckmark: loginItemEnabled,
                action: {
                    if loginItemNeedsApproval {
                        // Take user straight to the approval page
                        LoginItemManager.openSystemSettingsLoginItems()
                    } else {
                        let needsApproval = LoginItemManager.setEnabled(!loginItemEnabled)
                        loginItemEnabled = LoginItemManager.isEnabled
                        loginItemNeedsApproval = needsApproval
                        if needsApproval {
                            LoginItemManager.openSystemSettingsLoginItems()
                        }
                    }
                }
            )

            Divider()

            // Quit
            MenuButton(
                icon: "xmark.circle",
                title: "Quit Shhh",
                shortcut: "⌘Q",
                action: { NSApp.terminate(nil) }
            )
        }
        .frame(width: 280)
    }

    private var volumeOpacity: Double {
        if micState.inputVolume == 0 {
            return 0.3
        } else {
            // Fade from 0.3 to 1.0 based on volume (0-100)
            return 0.3 + (micState.inputVolume / 100.0) * 0.7
        }
    }

    private func showHotkeyRecorder() {
        Self.windowManager.showWindow(hotKeyManager: hotKeyManager)
    }

}

/// Standard macOS menu button - uses system default styling
struct MenuButton: View {
    let icon: String
    let title: String
    var shortcut: String? = nil
    var showCheckmark: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundColor(.primary)

                // Title
                Text(title)
                    .font(.system(size: 13))

                Spacer()

                // Checkmark or shortcut
                if showCheckmark {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.primary)
                } else if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Window Manager

/// Manages the hotkey recorder window to prevent multiple instances
@MainActor
final class HotkeyWindowManager {

    // MARK: - Properties

    /// Logger for window lifecycle events
    private let logger = Logger(subsystem: "com.sharabi.rj.Shhh", category: "WindowManager")

    /// The singleton window instance
    private var window: NSWindow?

    // MARK: - Public Methods

    /// Shows the hotkey recorder window, reusing existing instance if available
    /// - Parameter hotKeyManager: The hotkey manager to configure
    func showWindow(hotKeyManager: HotKeyManager) {
        // If window already exists and is visible, just bring it to front
        if let existingWindow = window, existingWindow.isVisible {
            logger.info("Hotkey recorder window already open, bringing to front")
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        logger.info("Creating new hotkey recorder window")

        // Create new window
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Record Keyboard Shortcut"
        newWindow.center()
        newWindow.isReleasedWhenClosed = false // Keep window in memory for reuse
        newWindow.contentView = NSHostingView(
            rootView: HotkeyRecorderView(
                hotKeyManager: hotKeyManager,
                window: newWindow
            )
        )

        // Store reference
        self.window = newWindow

        // Show window
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Closes the window if it exists
    func closeWindow() {
        window?.close()
    }
}

// MARK: - Preview

#Preview {
    MenuContentView(micState: MicState(), hotKeyManager: HotKeyManager.shared)
        .frame(width: 280)
}
