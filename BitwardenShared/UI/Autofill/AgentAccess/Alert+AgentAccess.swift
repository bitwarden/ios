import BitwardenKit
import BitwardenResources

extension Alert {
    /// An alert telling the user that agent requests won't show while the app is in the background
    /// because notifications are turned off, with an action to open the iOS Settings app.
    ///
    /// - Parameter openSettings: Called when the user taps "Open settings".
    /// - Returns: The alert.
    ///
    static func agentAccessNotificationsOff(openSettings: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.notificationsAreOff,
            message: Localizations.agentAccessNotificationsOffWarning,
            alertActions: [
                AlertAction(title: Localizations.openSettings, style: .default) { _, _ in
                    openSettings()
                },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ],
        )
    }
}
