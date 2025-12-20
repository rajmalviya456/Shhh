import SwiftUI
import Combine
import OSLog

/// Manages microphone state and volume control
///
/// This class provides a reactive interface to the system microphone state,
/// monitoring volume changes and providing methods to control the microphone.
@MainActor
final class MicState: ObservableObject {

    // MARK: - Published Properties

    @Published private(set) var inputVolume: Double
    @Published private(set) var isSilent: Bool
    @Published private(set) var lastError: Error?

    // MARK: - Private Properties

    private var volumeCheckTimer: Timer?
    private let updateInterval: TimeInterval = 0.5
    private let logger = Logger(subsystem: "com.sharabi.rj.Shhh", category: "MicState")

    /// Prevents timer updates while user is actively dragging the slider
    private var isUserAdjusting = false
    private var userAdjustmentDebounceTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {
        // Initialize with current system values
        let currentVolume = (try? MicController.getInputVolume()) ?? 0
        self.inputVolume = Double(currentVolume)
        self.isSilent = currentVolume == 0

        setupVolumeMonitoring()
    }

    deinit {
        volumeCheckTimer?.invalidate()
    }

    // MARK: - Public Methods

    /// Toggles microphone between muted and unmuted states
    func toggleMic() {
        do {
            if isSilent {
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
            lastError = error
        }
    }

    /// Sets the microphone volume to a specific level
    /// - Parameter volume: Volume level from 0 to 100
    func setVolume(_ volume: Double) {
        let clampedVolume = max(0, min(100, volume))

        // Mark that user is adjusting to prevent timer conflicts
        isUserAdjusting = true

        // Cancel any pending debounce task
        userAdjustmentDebounceTask?.cancel()

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
            lastError = error
        }

        // Debounce: Resume timer updates after user stops adjusting (500ms)
        userAdjustmentDebounceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            if !Task.isCancelled {
                isUserAdjusting = false
            }
        }
    }

    // MARK: - Private Methods

    /// Sets up periodic volume monitoring
    private func setupVolumeMonitoring() {
        volumeCheckTimer = Timer.scheduledTimer(
            withTimeInterval: updateInterval,
            repeats: true
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.updateVolume()
            }
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
            lastError = error
        }
    }
}
