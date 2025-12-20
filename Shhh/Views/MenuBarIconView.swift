import SwiftUI

/// Menu bar icon view with click-to-toggle functionality
struct MenuBarIconView: View {

    @ObservedObject var micState: MicState

    var body: some View {
        Image(systemName: "mic.fill")
            .font(.system(size: 14))
            .opacity(volumeOpacity)
            .help(micState.isSilent ? "Click to unmute • Right-click for menu" : "Click to mute • Right-click for menu")
            .onTapGesture {
                micState.toggleMic()
            }
    }

    private var volumeOpacity: Double {
        if micState.inputVolume == 0 {
            return 0.3
        } else {
            // Fade from 0.3 to 1.0 based on volume (0-100)
            return 0.3 + (micState.inputVolume / 100.0) * 0.7
        }
    }
}

