import BitwardenKit
import BitwardenResources

extension Alert {
    /// An alert telling the user that camera access is required to scan a card,
    /// with a "Settings" action to open the iOS app-settings page.
    ///
    /// - Parameter openSettings: Called when the user taps "Settings".
    /// - Returns: The camera permission required alert.
    ///
    static func cameraPermissionRequired(openSettings: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.camera,
            message: Localizations.enableCameraPermissionInSettingsToScanYourCard,
            alertActions: [
                AlertAction(title: Localizations.settings, style: .default) { _, _ in
                    openSettings()
                },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ],
        )
    }

    /// An alert notifying the user that the TOTP key scan was unsuccessful.
    ///
    /// - Returns: An alert notifying the user that the TOTP key scan was unsuccessful.
    ///
    static func totpScanFailureAlert() -> Alert {
        Alert(
            title: Localizations.authenticatorKeyReadError,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ],
        )
    }
}
