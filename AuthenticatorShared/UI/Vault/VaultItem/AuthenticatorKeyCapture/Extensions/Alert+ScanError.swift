import BitwardenResources

extension Alert {
    /// An alert notifying the user that the TOTP key scan was unsuccessful.
    ///
    /// - Returns: An alert notifying the user that the TOTP key scan was unsuccessful.
    ///
    static func totpScanFailureAlert() -> Alert {
        Alert(
            title: Localizations.keyReadError,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        )
    }
}
