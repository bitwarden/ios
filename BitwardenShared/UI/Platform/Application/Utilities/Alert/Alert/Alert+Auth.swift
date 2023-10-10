import Foundation

// MARK: - Alert+Auth

extension Alert {
    // MARK: Methods

    /// An alert notifying the user, upon creating an account, that their entered password has been found
    /// in a data breach.
    ///
    /// - Parameter action: The action to perform when the user taps `Yes`, opting to use the password anyways.
    ///
    /// - Returns An alert notifying the user that their entered password has been found in a data breach.
    ///
    static func breachesAlert(
        _ action: @escaping () -> Void
    ) -> Alert {
        Alert(
            title: Localizations.weakAndExposedMasterPassword,
            message: Localizations.weakPasswordIdentifiedAndFoundInADataBreachAlertDescription,
            alertActions: [
                AlertAction(title: Localizations.no, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in
                    action()
                },
            ]
        )
    }
}
