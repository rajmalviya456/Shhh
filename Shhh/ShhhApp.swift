import SwiftUI

/// Main application entry point
@main
struct ShhhApp: App {

    // MARK: - State Objects

    @StateObject private var micState = MicState()
    @StateObject private var hotKeyManager = HotKeyManager.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Initialization

    init() {
        // Note: We can't access @StateObject here directly, but we can use
        // the _micState and _hotKeyManager wrappers to get the wrapped values
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
                .onAppear {
                    // Initialize AppDelegate with state objects after view appears
                    appDelegate.initialize(micState: micState, hotKeyManager: hotKeyManager)
                    // Hide the window immediately
                    NSApplication.shared.windows.first?.close()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 0, height: 0)
    }
}
