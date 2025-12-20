import XCTest
@testable import Shhh

/// Tests for MicState functionality
@MainActor
final class MicStateTests: XCTestCase {

    var micState: MicState!

    override func setUp() async throws {
        try await super.setUp()
        micState = MicState()

        // Save current volume
        if let currentVolume = try? MicController.getInputVolume() {
            UserDefaults.standard.set(currentVolume, forKey: "test_saved_volume")
        }
    }

    override func tearDown() async throws {
        // Restore original volume
        if let savedVolume = UserDefaults.standard.value(forKey: "test_saved_volume") as? Int {
            try? MicController.setInputVolume(savedVolume)
        }
        UserDefaults.standard.removeObject(forKey: "test_saved_volume")

        micState = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        // Then: MicState should be initialized with current system volume
        XCTAssertGreaterThanOrEqual(micState.inputVolume, 0)
        XCTAssertLessThanOrEqual(micState.inputVolume, 100)
    }

    // MARK: - Toggle Tests

    func testToggleMicFromUnmuted() async throws {
        // Given: Mic is unmuted
        try MicController.setInputVolume(70)
        await Task.yield() // Allow state to update

        // When: Toggling mic
        micState.toggleMic()

        // Wait for async update
        try await Task.sleep(for: .milliseconds(100))

        // Then: Mic should be muted
        XCTAssertTrue(micState.isSilent)
        XCTAssertEqual(micState.inputVolume, 0)
    }

    func testToggleMicFromMuted() async throws {
        // Given: Mic is muted
        try MicController.setInputVolume(70)
        try MicController.silenceMic()
        await Task.yield()

        // When: Toggling mic
        micState.toggleMic()

        // Wait for async update
        try await Task.sleep(for: .milliseconds(100))

        // Then: Mic should be unmuted
        XCTAssertFalse(micState.isSilent)
        XCTAssertGreaterThan(micState.inputVolume, 0)
    }

    // MARK: - Volume Tests

    func testSetVolume() async throws {
        // When: Setting volume to 50
        micState.setVolume(50)

        // Wait for update
        try await Task.sleep(for: .milliseconds(100))

        // Then: Volume should be 50
        XCTAssertEqual(micState.inputVolume, 50)
        XCTAssertFalse(micState.isSilent)
    }

    func testSetVolumeToZero() async throws {
        // When: Setting volume to 0
        micState.setVolume(0)

        // Wait for update
        try await Task.sleep(for: .milliseconds(100))

        // Then: Should be silent
        XCTAssertEqual(micState.inputVolume, 0)
        XCTAssertTrue(micState.isSilent)
    }

    func testSetVolumeClamps() async throws {
        // When: Setting volume above 100
        micState.setVolume(150)

        // Then: Volume should be clamped to 100
        XCTAssertEqual(micState.inputVolume, 100)

        // When: Setting volume below 0
        micState.setVolume(-50)

        // Then: Volume should be clamped to 0
        XCTAssertEqual(micState.inputVolume, 0)
    }

    // MARK: - State Monitoring Tests

    func testVolumeMonitoring() async throws {
        // Given: Initial volume
        try MicController.setInputVolume(30)

        // Wait for monitoring to pick up change
        try await Task.sleep(for: .milliseconds(600))

        // Then: MicState should reflect the change
        XCTAssertEqual(Int(micState.inputVolume), 30)

        // When: Changing volume externally
        try MicController.setInputVolume(80)

        // Wait for monitoring
        try await Task.sleep(for: .milliseconds(600))

        // Then: MicState should update
        XCTAssertEqual(Int(micState.inputVolume), 80)
    }
}

