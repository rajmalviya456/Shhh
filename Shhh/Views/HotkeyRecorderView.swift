import SwiftUI
import HotKey

/// View for recording a new keyboard shortcut
struct HotkeyRecorderView: View {

    @ObservedObject var hotKeyManager: HotKeyManager
    let window: NSWindow
    @State private var recordedKey: String = "Press any key combination..."
    @State private var isRecording: Bool = true

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "keyboard")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)

                Text("Record Keyboard Shortcut")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            VStack(spacing: 12) {
                Text("Current shortcut:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(hotKeyManager.currentHotKeyDescription)
                    .font(.system(size: 24, weight: .bold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
            }

            if isRecording {
                Text(recordedKey)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            HStack(spacing: 12) {
                Button("Cancel") {
                    window.close()
                }
                .keyboardShortcut(.escape)

                Button("Reset to Default") {
                    hotKeyManager.registerHotKey(key: .m, modifiers: [.control, .option, .command])
                    window.close()
                }
            }
            .padding(.top, 8)
        }
        .padding(32)
        .frame(width: 400, height: 300)
        .background(KeyEventHandlerView(onKeyPress: handleKeyPress))
    }

    private func handleKeyPress(event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Ignore if only modifiers are pressed
        guard event.keyCode != 0 else { return }

        // Try to map to HotKey.Key
        if let key = keyFromKeyCode(event.keyCode) {
            hotKeyManager.registerHotKey(key: key, modifiers: modifiers)
            recordedKey = "Shortcut saved!"
            isRecording = false

            // Close window after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                window.close()
            }
        }
    }

    private func keyFromKeyCode(_ keyCode: UInt16) -> Key? {
        KeyHelper.key(from: keyCode)
    }
}

/// Helper view to capture key events
struct KeyEventHandlerView: NSViewRepresentable {
    let onKeyPress: (NSEvent) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = KeyCaptureView()
        view.onKeyPress = onKeyPress
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    class KeyCaptureView: NSView {
        var onKeyPress: ((NSEvent) -> Void)?

        override var acceptsFirstResponder: Bool { true }

        override func keyDown(with event: NSEvent) {
            onKeyPress?(event)
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            window?.makeFirstResponder(self)
        }
    }
}

