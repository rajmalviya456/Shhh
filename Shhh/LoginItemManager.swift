import AppKit
import OSLog
import ServiceManagement

/// Manages the app's login item status
enum LoginItemManager {

    private static let logger = Logger(subsystem: "com.sharabi.rj.Shhh", category: "LoginItem")

    // MARK: - Public Properties

    /// The current SMAppService status
    static var status: SMAppService.Status {
        SMAppService.mainApp.status
    }

    /// True only when fully enabled and approved by the user
    static var isEnabled: Bool {
        status == .enabled
    }

    /// True when registered but waiting for user approval in System Settings
    static var requiresApproval: Bool {
        status == .requiresApproval
    }

    // MARK: - Public Methods

    /// Enables or disables the app from starting at login.
    /// - Returns: `true` if the system needs the user to approve in System Settings.
    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                try SMAppService.mainApp.register()
                logger.info("Login item registered, status: \(String(describing: SMAppService.mainApp.status))")
            } else {
                try SMAppService.mainApp.unregister()
                logger.info("Login item unregistered")
            }
        } catch {
            logger.error("Failed to \(enabled ? "enable" : "disable") login item: \(error.localizedDescription)")
        }
        return SMAppService.mainApp.status == .requiresApproval
    }

    /// Opens System Settings to the Login Items page so the user can approve the app.
    static func openSystemSettingsLoginItems() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
