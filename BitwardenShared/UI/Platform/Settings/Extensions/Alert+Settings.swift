// MARK: - Alert + Settings

extension Alert {
    // MARK: Methods

    /// Confirms that the user wants to logout if their session times out.
    ///
    /// - Parameter action: The action performed when they select `Yes`.
    /// - Returns: An alert confirming that the user wants to logout if their session times out.
    ///
    static func logoutOnTimeoutAlert(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.warning,
            message: Localizations.vaultTimeoutLogOutConfirmation,
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _ in await action() },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ]
        )
    }

    /// An alert notifying the user that they will be navigated to the web app to set up two step login.
    ///
    /// - Parameters:
    ///   - action: The action to perform when the user confirms that they want to be navigated to the
    ///   web app.
    ///
    /// - Returns: An alert notifying the user that they will be navigated to the web app to set up two step login.
    ///
    static func twoStepLoginAlert(action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.continueToWebApp,
            message: Localizations.twoStepLoginDescriptionLong,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in
                    action()
                },
            ]
        )
    }
}
