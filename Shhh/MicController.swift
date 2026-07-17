import CoreAudio
import Foundation

/// Controls system microphone input volume via CoreAudio
///
/// This controller manages the default input device's volume through the
/// CoreAudio HAL. It supports muting, unmuting, volume adjustment, and
/// event-driven change notifications (no polling required).
@MainActor
enum MicController {

    // MARK: - Constants

    private static let lastVolumeKey = "com.shhh.lastMicVolume"
    private static let defaultRestoreVolume = 70

    // MARK: - Listener State

    private static var changeHandler: (@MainActor () -> Void)?
    private static var listenerDeviceID: AudioDeviceID = .init(kAudioObjectUnknown)

    /// C-convention callback registered with the HAL. A stable function
    /// pointer is required so the listener can be removed reliably.
    private static let volumeListenerProc: AudioObjectPropertyListenerProc = { _, _, _, _ in
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                MicController.changeHandler?()
            }
        }
        return noErr
    }

    // MARK: - Errors

    enum MicControllerError: Error, LocalizedError {
        case noInputDevice
        case volumeNotSupported
        case coreAudioError(OSStatus)

        var errorDescription: String? {
            switch self {
            case .noInputDevice:
                return "No default input device found"
            case .volumeNotSupported:
                return "The input device does not support volume control"
            case .coreAudioError(let status):
                return "CoreAudio call failed with status \(status)"
            }
        }
    }

    // MARK: - Public Methods

    /// Returns the current default input device
    /// - Returns: The AudioDeviceID of the default input device
    /// - Throws: MicControllerError if no input device is available
    static func defaultInputDeviceID() throws -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID
        )
        guard status == noErr else {
            throw MicControllerError.coreAudioError(status)
        }
        guard deviceID != kAudioObjectUnknown else {
            throw MicControllerError.noInputDevice
        }
        return deviceID
    }

    /// Gets the current input volume from the system
    /// - Returns: Volume level from 0 to 100
    /// - Throws: MicControllerError if the operation fails
    static func getInputVolume() throws -> Int {
        let deviceID = try defaultInputDeviceID()
        guard let element = volumeElements(for: deviceID).first else {
            throw MicControllerError.volumeNotSupported
        }

        var address = volumeAddress(element: element)
        var scalar = Float32(0)
        var size = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &scalar)
        guard status == noErr else {
            throw MicControllerError.coreAudioError(status)
        }
        return Int((scalar * 100).rounded())
    }

    /// Sets the input volume to a specific level
    /// - Parameter volume: Volume level from 0 to 100
    /// - Throws: MicControllerError if the operation fails
    static func setInputVolume(_ volume: Int) throws {
        let clampedVolume = max(0, min(100, volume))
        var scalar = Float32(clampedVolume) / 100

        let deviceID = try defaultInputDeviceID()
        let elements = volumeElements(for: deviceID)
        guard !elements.isEmpty else {
            throw MicControllerError.volumeNotSupported
        }

        for element in elements {
            var address = volumeAddress(element: element)
            let size = UInt32(MemoryLayout<Float32>.size)
            let status = AudioObjectSetPropertyData(
                deviceID, &address, 0, nil, size, &scalar)
            guard status == noErr else {
                throw MicControllerError.coreAudioError(status)
            }
        }
    }

    /// Mutes the microphone and saves the current volume for restoration
    /// - Throws: MicControllerError if the operation fails
    static func silenceMic() throws {
        let current = try getInputVolume()
        if current > 0 {
            UserDefaults.standard.set(current, forKey: lastVolumeKey)
        }
        try setInputVolume(0)
    }

    /// Restores the microphone to the previously saved volume
    /// - Throws: MicControllerError if the operation fails
    static func restoreMic() throws {
        let lastVolume = UserDefaults.standard.integer(forKey: lastVolumeKey)
        let volumeToRestore = lastVolume > 0 ? lastVolume : defaultRestoreVolume
        try setInputVolume(volumeToRestore)
    }

    /// Checks if the microphone is currently muted
    /// - Returns: True if volume is 0, false otherwise
    static func isSilent() -> Bool {
        (try? getInputVolume()) == 0
    }

    // MARK: - Change Listener

    /// Registers a handler invoked whenever the input volume changes.
    /// Replaces any previously registered handler.
    /// - Parameter handler: Called on the main actor after each volume change
    /// - Throws: MicControllerError if the listener cannot be installed
    static func addVolumeChangeListener(_ handler: @escaping @MainActor () -> Void) throws {
        removeVolumeChangeListener()

        let deviceID = try defaultInputDeviceID()
        var address = volumeAddress(element: kAudioObjectPropertyElementWildcard)
        let status = AudioObjectAddPropertyListener(deviceID, &address, volumeListenerProc, nil)
        guard status == noErr else {
            throw MicControllerError.coreAudioError(status)
        }

        changeHandler = handler
        listenerDeviceID = deviceID
    }

    /// Removes the currently registered volume change handler, if any
    static func removeVolumeChangeListener() {
        guard changeHandler != nil else { return }
        var address = volumeAddress(element: kAudioObjectPropertyElementWildcard)
        AudioObjectRemovePropertyListener(listenerDeviceID, &address, volumeListenerProc, nil)
        changeHandler = nil
        listenerDeviceID = AudioDeviceID(kAudioObjectUnknown)
    }

    // MARK: - Private Helpers

    private static func volumeAddress(
        element: AudioObjectPropertyElement
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: element
        )
    }

    /// Elements carrying an input volume control: the main element when
    /// available, otherwise the individual channels.
    private static func volumeElements(
        for deviceID: AudioDeviceID
    ) -> [AudioObjectPropertyElement] {
        var mainAddress = volumeAddress(element: kAudioObjectPropertyElementMain)
        if AudioObjectHasProperty(deviceID, &mainAddress) {
            return [kAudioObjectPropertyElementMain]
        }

        var channels: [AudioObjectPropertyElement] = []
        for channel: AudioObjectPropertyElement in 1...2 {
            var address = volumeAddress(element: channel)
            if AudioObjectHasProperty(deviceID, &address) {
                channels.append(channel)
            }
        }
        return channels
    }
}
