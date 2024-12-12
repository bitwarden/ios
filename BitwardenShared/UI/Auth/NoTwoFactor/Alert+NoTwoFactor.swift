// MARK: - Alert + NoTwoFactor

extension Alert {
    // MARK: Methods

    /// An alert that asks if the user wants to change their email
    /// in a browser.
    ///
    /// - Parameters:
    ///   - action: The action taken if they select continue.
    /// - Returns: An alert that asks if the user wants to navigate to the change email page
    ///
    static func changeEmailAlert(action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.changeEmail,
            message: Localizations.changeEmailConfirmation,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.continue, style: .default) { _ in
                    action()
                },
            ]
        )
    }

    /// An alert that asks if the user wants to turn two-factor login on
    /// in a browser.
    ///
    /// - Parameters:
    ///   - action: The action taken if they select continue.
    /// - Returns: An alert that asks if the user wants to navigate to the two-factor login setup page
    ///
    static func turnOnTwoFactorLoginAlert(action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.turnOnTwoStepLogin,
            message: Localizations.turnOnTwoStepLogin,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.continue, style: .default) { _ in
                    action()
                },
            ]
        )
    }
}
