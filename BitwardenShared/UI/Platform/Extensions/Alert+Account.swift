// MARK: - Alert+Account

extension Alert {
    /// An alert notifying the user that their account has been permanently deleted.
    ///
    /// - Returns: An alert notifying the user that their account has been permanently deleted.
    ///
    static func accountDeletedAlert() -> Alert {
        Alert(
            title: Localizations.yourAccountHasBeenPermanentlyDeleted,
            message: nil,
            alertActions: [AlertAction(title: Localizations.ok, style: .default)]
        )
    }
}
