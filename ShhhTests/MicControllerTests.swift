import XCTest
@testable import Shhh

/// Tests for MicController functionality
@MainActor
final class MicControllerTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        // Save current volume to restore later
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
        try await super.tearDown()
    }

    // MARK: - Volume Tests

    func testGetInputVolume() throws {
        // When: Getting input volume
        let volume = try MicController.getInputVolume()

        // Then: Volume should be between 0 and 100
        XCTAssertGreaterThanOrEqual(volume, 0)
        XCTAssertLessThanOrEqual(volume, 100)
    }

    func testSetInputVolume() throws {
        // Given: A specific volume level
        let testVolume = 50

        // When: Setting the volume
        try MicController.setInputVolume(testVolume)

        // Then: Volume should be set correctly
        let currentVolume = try MicController.getInputVolume()
        XCTAssertEqual(currentVolume, testVolume)
    }

    func testSetInputVolumeClamps() throws {
        // When: Setting volume above 100
        try MicController.setInputVolume(150)

        // Then: Volume should be clamped to 100
        let volume = try MicController.getInputVolume()
        XCTAssertEqual(volume, 100)

        // When: Setting volume below 0
        try MicController.setInputVolume(-50)

        // Then: Volume should be clamped to 0
        let volumeAfter = try MicController.getInputVolume()
        XCTAssertEqual(volumeAfter, 0)
    }

    // MARK: - Mute/Unmute Tests

    func testSilenceMic() throws {
        // Given: Mic is not muted
        try MicController.setInputVolume(70)

        // When: Silencing the mic
        try MicController.silenceMic()

        // Then: Volume should be 0
        let volume = try MicController.getInputVolume()
        XCTAssertEqual(volume, 0)
        XCTAssertTrue(MicController.isSilent())
    }

    func testRestoreMic() throws {
        // Given: Mic is muted after being at 70%
        try MicController.setInputVolume(70)
        try MicController.silenceMic()

        // When: Restoring the mic
        try MicController.restoreMic()

        // Then: Volume should be restored to 70
        let volume = try MicController.getInputVolume()
        XCTAssertEqual(volume, 70)
        XCTAssertFalse(MicController.isSilent())
    }

    func testIsSilent() throws {
        // When: Volume is 0
        try MicController.setInputVolume(0)

        // Then: Should be silent
        XCTAssertTrue(MicController.isSilent())

        // When: Volume is not 0
        try MicController.setInputVolume(50)

        // Then: Should not be silent
        XCTAssertFalse(MicController.isSilent())
    }
}

