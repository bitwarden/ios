import Foundation

// MARK: - Alert+Auth

extension Alert {
    // MARK: Methods

    /// An alert notifying the user that they haven't agreed to the terms of service and privacy policy.
    ///
    /// - Returns: An alert notifying the user that they haven't agreed to the terms of service and privacy policy.
    ///
    static func acceptPoliciesAlert() -> Alert {
        Alert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.acceptPoliciesError,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        )
    }

    /// An alert notifying the user, upon creating an account, that their entered password has been found
    /// in a data breach.
    ///
    /// - Parameter action: The action to perform when the user taps `Yes`, opting to use the password anyways.
    ///
    /// - Returns: An alert notifying the user that their entered password has been found in a data breach.
    ///
    static func breachesAlert(
        _ action: @escaping () async -> Void
    ) -> Alert {
        Alert(
            title: Localizations.weakAndExposedMasterPassword,
            message: Localizations.weakPasswordIdentifiedAndFoundInADataBreachAlertDescription,
            alertActions: [
                AlertAction(title: Localizations.no, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in
                    await action()
                },
            ]
        )
    }
}
