// MARK: - Alert+Account

extension Alert {
    /// An alert notifying the user that their account has been permanently deleted.
    ///
    /// - Returns: An alert notifying the user that their account has been permanently deleted.
    ///
    static func accountDeleted() -> Alert {
        Alert(
            title: Localizations.yourAccountHasBeenPermanentlyDeleted,
            message: nil,
            alertActions: [AlertAction(title: Localizations.ok, style: .default)]
        )
    }

    /// An alert verifying that the user wants to delete the account.
    ///
    /// - Parameter action: The action to perform when the user taps submit.
    /// - Returns: An alert verifying that the user wants to delete the account.
    ///
    static func deleteAccountAlert(_ action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.passwordConfirmation,
            message: Localizations.passwordConfirmationDesc,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.submit, style: .default, handler: { _ in
                    await action()
                }),
            ]
        )
    }
}
