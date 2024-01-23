// MARK: - Alert + Settings

extension Alert {
    // MARK: Methods

    /// An alert that asks if the user wants to navigate to the app store to leave a review.
    ///
    /// - Parameter action: The action taken if they select continue.
    /// - Returns: An alert that asks if the user wants to navigate to the app store to leave a review.
    ///
    static func appStoreAlert(action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.continueToAppStore,
            message: Localizations.rateAppDescriptionLong,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.continue, style: .default) { _ in
                    action()
                },
            ]
        )
    }

    /// Confirm allowing the device to approve login requests.
    ///
    /// - Parameter action: The action to perform if the user selects yes.
    ///
    /// - Returns: An alert confirming allowing the device to approve login requests.
    ///
    static func confirmApproveLoginRequests(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.approveLoginRequests,
            message: Localizations.useThisDeviceToApproveLoginRequestsMadeFromOtherDevices,
            alertActions: [
                AlertAction(title: Localizations.no, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in await action() },

            ]
        )
    }

    /// Confirm deleting the folder.
    ///
    /// - Parameter action: The action to perform if the user selects yes.
    ///
    /// - Returns: An alert to confirm deleting the folder.
    ///
    static func confirmDeleteFolder(action: @MainActor @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.doYouReallyWantToDelete,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _ in await action() },
                AlertAction(title: Localizations.no, style: .cancel),
            ]
        )
    }

    /// Confirm denying all the login requests.
    ///
    /// - Parameter action: The action to perform if the user selects yes.
    ///
    /// - Returns: An alert to confirm denying all the login requests.
    ///
    static func confirmDenyingAllRequests(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.areYouSureYouWantToDeclineAllPendingLogInRequests,
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.no, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in await action() },
            ]
        )
    }

    /// Confirm that the user wants to export their vault.
    ///
    /// - Parameters:
    ///   - encrypted: Whether the user is attempting to export their vault encrypted or not.
    ///   - action: The action performed when they select export vault.
    ///
    /// - Returns: An alert confirming that the user wants to export their vault unencrypted.
    ///
    static func confirmExportVault(encrypted: Bool, action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.exportVaultConfirmationTitle,
            message: encrypted ?
                (Localizations.encExportKeyWarning + .newLine + Localizations.encExportAccountWarning) :
                Localizations.exportVaultWarning,
            alertActions: [
                AlertAction(title: Localizations.exportVault, style: .default) { _ in await action() },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ]
        )
    }

    /// Displays the account fingerprint phrase alert.
    ///
    /// - Parameters:
    ///   - action: The action to perform when the user selects `Learn more`.
    ///   - phrase: The user's fingerprint phrase.
    ///
    /// - Returns: An alert that displays the user's fingerprint phrase and prompts them to learn more about it.
    ///
    static func displayFingerprintPhraseAlert(_ action: @escaping () async -> Void, phrase: String) -> Alert {
        Alert(
            title: Localizations.fingerprintPhrase,
            message: "\(Localizations.yourAccountsFingerprint):\n\n\(phrase)",
            alertActions: [
                AlertAction(title: Localizations.close, style: .cancel),
                AlertAction(title: Localizations.learnMore, style: .default) { _ in await action() },
            ]
        )
    }

    /// An alert that prompts the user to enter their PIN.
    ///
    /// - Parameter completion: The code block that's executed when the user has entered their pin.
    /// - Returns: An alert that prompts the user to enter their PIN.
    ///
    static func enterPINCode(completion: @MainActor @escaping (String) async -> Void) -> Alert {
        Alert(
            title: Localizations.enterPIN,
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

    /// Show the alert notifying the user that the language has been changed.
    ///
    /// - Parameters:
    ///   - newLanguage: The title of the new language.
    ///   - action: The action to run after the user clicks ok.
    /// - Returns: An alert confirming the language change.
    ///
    @MainActor
    static func languageChanged(to newLanguage: String, action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.languageChangeXDescription(newLanguage),
            message: nil,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default) { _ in
                    action()
                },
            ]
        )
    }

    /// Confirms that the user wants to logout if their session times out.
    ///
    /// - Parameter action: The action performed when they select `Yes`.
    ///
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
    /// - Parameter action: The action to perform when the user confirms that they want to be navigated to the
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
