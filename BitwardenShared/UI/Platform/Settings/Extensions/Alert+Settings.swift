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

    /// An alert that prompts the user to enter their PIN.
    ///
    /// - Parameter completion: The code block that's executed when the user has entered their pin.
    /// - Returns: An alert that prompts the user to enter their PIN.
    ///
    static func unlockWithPIN(completion: @MainActor @escaping (String) async -> Void) -> Alert {
        Alert(
            title: Localizations.unlockWithPIN,
            message: Localizations.setPINDescription,
            alertActions: [
                AlertAction(
                    title: Localizations.submit,
                    style: .default,
                    handler: { _, alertTextFields in
                        guard let password = alertTextFields.first(where: { $0.id == "pin" })?.text else { return }
                        await completion(password)
                    }
                ),
                AlertAction(title: Localizations.cancel, style: .cancel),
            ],
            alertTextFields: [
                AlertTextField(
                    id: "pin",
                    autocapitalizationType: .none,
                    autocorrectionType: .no,
                    keyboardType: .numberPad
                ),
            ]
        )
    }
}
