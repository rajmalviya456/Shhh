import AppKit
import HotKey
import Combine
import OSLog

/// Manages global keyboard shortcuts for microphone control
///
/// This class handles registration and management of global hotkeys for controlling
/// the microphone state. It persists hotkey preferences and provides a reactive interface.
@MainActor
final class HotKeyManager: ObservableObject {

    // MARK: - Singleton

    static let shared = HotKeyManager()

    // MARK: - Published Properties

    @Published private(set) var currentHotKeyDescription: String = "⌃⌥⌘M"
    @Published var isRecording: Bool = false

    // MARK: - Private Properties

    private var hotKey: HotKey?
    private weak var micState: MicState?
    private let logger = Logger(subsystem: "com.sharabi.rj.Shhh", category: "HotKeyManager")

    // MARK: - Initialization

    private init() {
        // Hotkey will be set up after micState is connected
    }

    // MARK: - Public Methods

    /// Connects the hotkey manager to the mic state
    /// - Parameter micState: The microphone state to control
    func connect(to micState: MicState) {
        logger.info("Connecting HotKeyManager to MicState")
        self.micState = micState
        setupDefaultHotKey()
    }

    /// Registers a new hotkey combination
    /// - Parameters:
    ///   - key: The key to register
    ///   - modifiers: The modifier flags (Control, Option, Command, etc.)
    func registerHotKey(key: Key, modifiers: NSEvent.ModifierFlags) {
        // Unregister existing hotkey
        hotKey = nil

        // Register new hotkey
        let newHotKey = HotKey(key: key, modifiers: modifiers)
        newHotKey.keyDownHandler = { [weak self] in
            guard let self = self else { return }
            self.logger.debug("Hotkey pressed")
            Task { @MainActor in
                self.micState?.toggleMic()
            }
        }

        self.hotKey = newHotKey
        updateHotKeyDescription(key: key, modifiers: modifiers)

        logger.info("Registered hotkey: \(self.currentHotKeyDescription)")

        // Save to UserDefaults
        saveHotKey(key: key, modifiers: modifiers)
    }

    // MARK: - Private Methods

    /// Sets up the default hotkey (Control + Option + Command + M) or loads saved
    private func setupDefaultHotKey() {
        if let (key, modifiers) = loadSavedHotKey() {
            registerHotKey(key: key, modifiers: modifiers)
        } else {
            registerHotKey(key: .m, modifiers: [.control, .option, .command])
        }
    }

    /// Saves the hotkey configuration
    private func saveHotKey(key: Key, modifiers: NSEvent.ModifierFlags) {
        UserDefaults.standard.set(key.carbonKeyCode, forKey: "hotkey_keycode")
        UserDefaults.standard.set(modifiers.rawValue, forKey: "hotkey_modifiers")
    }

    /// Loads saved hotkey or uses default
    private func loadSavedHotKey() -> (Key, NSEvent.ModifierFlags)? {
        guard let keyCode = UserDefaults.standard.value(forKey: "hotkey_keycode") as? UInt32 else {
            return nil
        }
        let modifiersRaw = UserDefaults.standard.value(forKey: "hotkey_modifiers") as? UInt ?? 0
        let modifiers = NSEvent.ModifierFlags(rawValue: modifiersRaw)

        // Try to find the key from carbon key code
        if let key = KeyHelper.allKeys.first(where: { $0.carbonKeyCode == keyCode }) {
            return (key, modifiers)
        }
        return nil
    }

    /// Updates the displayed hotkey description
    private func updateHotKeyDescription(key: Key, modifiers: NSEvent.ModifierFlags) {
        var description = ""

        if modifiers.contains(.control) { description += "⌃" }
        if modifiers.contains(.option) { description += "⌥" }
        if modifiers.contains(.shift) { description += "⇧" }
        if modifiers.contains(.command) { description += "⌘" }

        description += KeyHelper.description(for: key)
        currentHotKeyDescription = description
    }
}

// MARK: - Key Helpers

/// Helper utilities for HotKey.Key to avoid extending imported types
enum KeyHelper {

    /// Returns a human-readable description for a key
    /// - Parameter key: The key to describe
    /// - Returns: A string representation of the key
    static func description(for key: Key) -> String {
        switch key {
        case .a: return "A"
        case .b: return "B"
        case .c: return "C"
        case .d: return "D"
        case .e: return "E"
        case .f: return "F"
        case .g: return "G"
        case .h: return "H"
        case .i: return "I"
        case .j: return "J"
        case .k: return "K"
        case .l: return "L"
        case .m: return "M"
        case .n: return "N"
        case .o: return "O"
        case .p: return "P"
        case .q: return "Q"
        case .r: return "R"
        case .s: return "S"
        case .t: return "T"
        case .u: return "U"
        case .v: return "V"
        case .w: return "W"
        case .x: return "X"
        case .y: return "Y"
        case .z: return "Z"
        default: return "?"
        }
    }

    /// All supported letter keys
    static let allKeys: [Key] = [
        .a, .b, .c, .d, .e, .f, .g, .h, .i, .j, .k, .l, .m,
        .n, .o, .p, .q, .r, .s, .t, .u, .v, .w, .x, .y, .z
    ]

    /// Finds a key from its carbon key code
    /// - Parameter keyCode: The carbon key code
    /// - Returns: The matching Key, or nil if not found
    static func key(from keyCode: UInt16) -> Key? {
        allKeys.first { $0.carbonKeyCode == UInt32(keyCode) }
    }
}
