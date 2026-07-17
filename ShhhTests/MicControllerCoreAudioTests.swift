import CoreAudio
import XCTest

@testable import Shhh

/// Tests for the CoreAudio-backed MicController APIs
@MainActor
final class MicControllerCoreAudioTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        if let currentVolume = try? MicController.getInputVolume() {
            UserDefaults.standard.set(currentVolume, forKey: "test_saved_volume")
        }
    }

    override func tearDown() async throws {
        MicController.removeVolumeChangeListener()
        if let savedVolume = UserDefaults.standard.value(forKey: "test_saved_volume") as? Int {
            try? MicController.setInputVolume(savedVolume)
        }
        UserDefaults.standard.removeObject(forKey: "test_saved_volume")
        try await super.tearDown()
    }

    // MARK: - Device Query

    func testDefaultInputDeviceIDIsValid() throws {
        // When: Querying the default input device
        let deviceID = try MicController.defaultInputDeviceID()

        // Then: A real device is returned
        XCTAssertNotEqual(deviceID, kAudioObjectUnknown)
    }

    // MARK: - Change Listener

    func testVolumeChangeListenerFiresOnExternalChange() async throws {
        // Given: A known starting volume and a registered listener
        try MicController.setInputVolume(40)

        let expectation = expectation(description: "volume change listener fired")
        expectation.assertForOverFulfill = false
        try MicController.addVolumeChangeListener {
            expectation.fulfill()
        }

        // When: The volume changes underneath the listener
        try MicController.setInputVolume(60)

        // Then: The listener fires without any polling
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    func testRemoveVolumeChangeListenerStopsCallbacks() async throws {
        // Given: A registered then removed listener
        try MicController.setInputVolume(40)

        var fireCount = 0
        try MicController.addVolumeChangeListener {
            fireCount += 1
        }
        MicController.removeVolumeChangeListener()

        // Drain callbacks already in flight from before removal
        try await Task.sleep(for: .milliseconds(500))
        let countAfterRemoval = fireCount

        // When: The volume changes after removal
        try MicController.setInputVolume(60)
        try await Task.sleep(for: .milliseconds(500))

        // Then: No further callbacks arrive
        XCTAssertEqual(fireCount, countAfterRemoval)
    }
}
