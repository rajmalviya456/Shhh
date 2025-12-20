import ServiceManagement

/// Manages the app's login item status
enum LoginItemManager {

    // MARK: - Public Properties

    /// Checks if the app is set to start at login
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    // MARK: - Public Methods

    /// Enables or disables the app from starting at login
    /// - Parameter enabled: True to enable, false to disable
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") login item: \(error)")
        }
    }
}
