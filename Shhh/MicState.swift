import Combine
import OSLog
import SwiftUI

/// Manages microphone state and volume control
///
/// This class provides a reactive interface to the system microphone state,
/// monitoring volume changes and providing methods to control the microphone.
@MainActor
final class MicState: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var inputVolume: Double
    @Published private(set) var isSilent: Bool

    // MARK: - Private Properties

    private let logger = Logger(subsystem: "com.sharabi.rj.Shhh", category: "MicState")

    // MARK: - Initialization

    init() {
        // Initialize with current system values
        let currentVolume = (try? MicController.getInputVolume()) ?? 0
        self.inputVolume = Double(currentVolume)
        self.isSilent = currentVolume == 0

        setupVolumeMonitoring()
    }

    // MARK: - Public Methods

    /// Toggles microphone between muted and unmuted states
    func toggleMic() {
        do {
            // Decide from live hardware state so a toggle immediately after an
            // external change can't act on a stale cached value
            if MicController.isSilent() {
                try MicController.restoreMic()
                logger.info("Microphone unmuted")
            } else {
                try MicController.silenceMic()
                logger.info("Microphone muted")
            }
            Task {
                await updateVolume()
                NotificationCenter.default.post(
                    name: NSNotification.Name("MicStateChanged"),
                    object: nil
                )
            }
        } catch {
            logger.error("Failed to toggle microphone: \(error.localizedDescription)")
        }
    }

    /// Sets the microphone volume to a specific level
    /// - Parameter volume: Volume level from 0 to 100
    func setVolume(_ volume: Double) {
        let clampedVolume = max(0, min(100, volume))

        // Update immediately for responsive UI
        inputVolume = clampedVolume
        isSilent = clampedVolume == 0

        do {
            try MicController.setInputVolume(Int(clampedVolume))

            NotificationCenter.default.post(
                name: NSNotification.Name("MicStateChanged"),
                object: nil
            )

            logger.debug("Volume set to \(Int(clampedVolume))%")
        } catch {
            logger.error("Failed to set volume: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    /// Subscribes to CoreAudio volume change notifications (event-driven, no polling)
    private func setupVolumeMonitoring() {
        do {
            try MicController.addVolumeChangeListener { [weak self] in
                guard let self = self else { return }
                Task { @MainActor in
                    await self.updateVolume()
                }
            }
        } catch {
            logger.error(
                "Failed to install volume change listener: \(error.localizedDescription)")
        }
    }

    /// Updates the current volume from the system
    private func updateVolume() async {
        do {
            let volume = try MicController.getInputVolume()
            inputVolume = Double(volume)
            isSilent = volume == 0
        } catch {
            logger.error("Failed to get volume: \(error.localizedDescription)")
        }
    }
}
