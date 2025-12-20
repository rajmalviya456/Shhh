import Foundation

/// Controls system microphone input volume via AppleScript
///
/// This controller provides a simple interface to manage the system microphone volume
/// using AppleScript commands. It supports muting, unmuting, and volume adjustment.
@MainActor
enum MicController: Sendable {

    // MARK: - Constants

    private static let lastVolumeKey = "com.shhh.lastMicVolume"
    private static let defaultRestoreVolume = 70

    // MARK: - Errors

    enum MicControllerError: Error, LocalizedError {
        case scriptCreationFailed
        case scriptExecutionFailed(String)

        var errorDescription: String? {
            switch self {
            case .scriptCreationFailed:
                return "Failed to create AppleScript"
            case .scriptExecutionFailed(let message):
                return "AppleScript execution failed: \(message)"
            }
        }
    }

    // MARK: - Public Methods

    /// Gets the current input volume from the system
    /// - Returns: Volume level from 0 to 100
    /// - Throws: MicControllerError if the operation fails
    static func getInputVolume() throws -> Int {
        let script = "input volume of (get volume settings)"
        guard let appleScript = NSAppleScript(source: script) else {
            throw MicControllerError.scriptCreationFailed
        }

        var error: NSDictionary?
        let result = appleScript.executeAndReturnError(&error)

        if let error = error {
            throw MicControllerError.scriptExecutionFailed(error.description)
        }

        return Int(result.int32Value)
    }

    /// Sets the input volume to a specific level
    /// - Parameter volume: Volume level from 0 to 100
    /// - Throws: MicControllerError if the operation fails
    static func setInputVolume(_ volume: Int) throws {
        let clampedVolume = max(0, min(100, volume))
        let script = "set volume input volume \(clampedVolume)"

        guard let appleScript = NSAppleScript(source: script) else {
            throw MicControllerError.scriptCreationFailed
        }

        var error: NSDictionary?
        appleScript.executeAndReturnError(&error)

        if let error = error {
            throw MicControllerError.scriptExecutionFailed(error.description)
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
}
