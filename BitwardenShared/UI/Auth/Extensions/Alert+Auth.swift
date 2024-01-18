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

    /// Display the options to log out of or lock the selected profile switcher item.
    ///
    /// - Parameters:
    ///   - account: The selected item from the profile switcher view.
    ///   - lockAction: The action to perform if the user chooses to lock the account.
    ///   - logoutAction: The action to perform if the user chooses to log out of the account.
    ///
    /// - Returns: An alert displaying the options for the item.
    ///
    static func accountOptions(
        _ item: ProfileSwitcherItem,
        lockAction: @escaping () async -> Void,
        logoutAction: @escaping () async -> Void
    ) -> Alert {
        // All accounts have the option to log out, but only display the lock option if
        // the account is not currently locked.
        var alertActions = [
            AlertAction(
                title: Localizations.logOut,
                style: .default,
                handler: { _, _ in await logoutAction() }
            ),
        ]
        if item.isUnlocked {
            alertActions.insert(
                AlertAction(
                    title: Localizations.lock,
                    style: .default,
                    handler: { _, _ in await lockAction() }
                ),
                at: 0
            )
        }

        return Alert(
            title: item.email,
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: alertActions + [AlertAction(title: Localizations.cancel, style: .cancel)]
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

    /// An alert that is displayed to confirm the user wants to log out of the account.
    ///
    /// - Parameter action: An action to perform when the user taps `Yes`, to confirm logout.
    /// - Returns: An alert that is displayed to confirm the user wants to log out of the account.
    ///
    static func logoutConfirmation(
        action: @escaping () async -> Void
    ) -> Alert {
        Alert(
            title: Localizations.logOut,
            message: Localizations.logoutConfirmation,
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _ in await action() },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ]
        )
    }
}
