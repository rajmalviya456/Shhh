import XCTest
import HotKey
@testable import Shhh

/// Tests for HotKeyManager functionality
@MainActor
final class HotKeyManagerTests: XCTestCase {

    var hotKeyManager: HotKeyManager!
    var micState: MicState!

    override func setUp() async throws {
        try await super.setUp()
        hotKeyManager = HotKeyManager.shared
        micState = MicState()

        // Clear saved hotkey
        UserDefaults.standard.removeObject(forKey: "hotkey_keycode")
        UserDefaults.standard.removeObject(forKey: "hotkey_modifiers")
    }

    override func tearDown() async throws {
        hotKeyManager = nil
        micState = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testDefaultHotKey() {
        // When: Connecting to mic state
        hotKeyManager.connect(to: micState)

        // Then: Default hotkey should be set
        XCTAssertEqual(hotKeyManager.currentHotKeyDescription, "⌃⌥⌘M")
    }

    // MARK: - Registration Tests

    func testRegisterHotKey() {
        // When: Registering a new hotkey
        hotKeyManager.registerHotKey(key: .k, modifiers: [.command, .shift])

        // Then: Description should be updated
        XCTAssertEqual(hotKeyManager.currentHotKeyDescription, "⇧⌘K")
    }

    func testHotKeySaveAndLoad() {
        // Given: A registered hotkey
        hotKeyManager.registerHotKey(key: .p, modifiers: [.control, .option])

        // When: Creating a new instance
        let newManager = HotKeyManager.shared
        newManager.connect(to: micState)

        // Then: Hotkey should be loaded from UserDefaults
        XCTAssertEqual(newManager.currentHotKeyDescription, "⌃⌥P")
    }

    // MARK: - Description Tests

    func testHotKeyDescriptionWithAllModifiers() {
        // When: Registering with all modifiers
        hotKeyManager.registerHotKey(
            key: .a,
            modifiers: [.control, .option, .shift, .command]
        )

        // Then: Description should include all modifiers
        let description = hotKeyManager.currentHotKeyDescription
        XCTAssertTrue(description.contains("⌃"))
        XCTAssertTrue(description.contains("⌥"))
        XCTAssertTrue(description.contains("⇧"))
        XCTAssertTrue(description.contains("⌘"))
        XCTAssertTrue(description.contains("A"))
    }

    func testHotKeyDescriptionWithNoModifiers() {
        // When: Registering with no modifiers
        hotKeyManager.registerHotKey(key: .z, modifiers: [])

        // Then: Description should only show the key
        XCTAssertEqual(hotKeyManager.currentHotKeyDescription, "Z")
    }

    // MARK: - Recording State Tests

    func testRecordingState() {
        // Given: Not recording
        XCTAssertFalse(hotKeyManager.isRecording)

        // When: Setting recording state
        hotKeyManager.isRecording = true

        // Then: Should be recording
        XCTAssertTrue(hotKeyManager.isRecording)
    }
}

