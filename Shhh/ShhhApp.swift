import SwiftUI

/// Main application entry point
@main
struct ShhhApp: App {

    // MARK: - App Delegate

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // MARK: - Scene

    var body: some Scene {
        // A Settings scene satisfies SwiftUI's requirement for at least one scene
        // without creating a visible window. All real setup happens in AppDelegate.
        Settings {
            EmptyView()
        }
    }
}
