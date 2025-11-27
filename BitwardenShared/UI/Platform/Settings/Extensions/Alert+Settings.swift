import BitwardenKit
import BitwardenResources

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
            ],
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
            ],
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
            ],
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
            message: encrypted ? Localizations.exportVaultFilePwProtectInfo : Localizations.exportVaultWarning,
            alertActions: [
                AlertAction(title: Localizations.exportVault, style: .default) { _ in await action() },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ],
        )
    }

    /// Displays the account fingerprint phrase alert.
    ///
    /// - Parameters:
    ///   - phrase: The user's fingerprint phrase.
    ///   - action: The action to perform when the user selects `Learn more`.
    ///
    /// - Returns: An alert that displays the user's fingerprint phrase and prompts them to learn more about it.
    ///
    static func displayFingerprintPhraseAlert(phrase: String, action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.fingerprintPhrase,
            message: "\(Localizations.yourAccountsFingerprint):\n\n\(phrase)",
            alertActions: [
                AlertAction(title: Localizations.close, style: .cancel),
                AlertAction(title: Localizations.learnMore, style: .default) { _ in await action() },
            ],
        )
    }

    /// An alert that asks if the user wants to navigate to the "import items" page in a browser.
    ///
    /// - Parameter action: The action taken if they select continue.
    /// - Returns: An alert that asks if the user wants to navigate to the import items page.
    ///
    static func importItemsAlert(importUrl: String, action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.continueToWebApp,
            message: Localizations.youCanImportDataToYourVaultOnX(importUrl),
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.continue, style: .default) { _ in
                    action()
                },
            ],
        )
    }

    /// An alert that asks if the user wants to navigate to the "learn about organizations" help page in a browser.
    ///
    /// - Parameter action: The action taken if they select continue.
    /// - Returns: An alert that asks if the user wants to navigate to the app store to leave a review.
    ///
    static func learnAboutOrganizationsAlert(action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.learnOrg,
            message: Localizations.learnAboutOrganizationsDescriptionLong,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.continue, style: .default) { _ in
                    action()
                },
            ],
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
            ],
        )
    }

    /// Confirms that the user wants to set their vault timeout to never.
    ///
    /// - Parameter action: The action performed when they select `Yes`.
    ///
    /// - Returns: An alert confirming that the user wants to set their vault timeout to never.
    ///
    static func neverLockAlert(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.warning,
            message: Localizations.neverLockWarning,
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _ in await action() },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ],
        )
    }

    /// An alert that asks if the user wants to navigate to the privacy policy in a browser.
    ///
    /// - Parameter action: The action taken if they select continue.
    /// - Returns: An alert that asks if the user wants to navigate to the app store to leave a review.
    ///
    static func privacyPolicyAlert(action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.continueToPrivacyPolicy,
            message: Localizations.privacyPolicyDescriptionLong,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.continue, style: .default) { _ in
                    action()
                },
            ],
        )
    }

    /// Alerts the user that their selected timeout value exceeds the policy's limit.
    ///
    /// - Returns an alert notifying the user that their selected timeout value exceeds the policy's limit.
    ///
    static func timeoutExceedsPolicyLengthAlert() -> Alert {
        Alert(
            title: Localizations.warning,
            message: Localizations.vaultTimeoutToLarge,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ],
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
            ],
        )
    }

    /// An alert asking if the user wants to login with their PIN upon app restart.
    ///
    /// - Parameters:
    ///   - biometricType: The biometric type the app supports.
    ///   - action: The action to occur if `Yes` is tapped
    ///
    /// - Returns: An alert asking if the user wants to login with their PIN upon app restart.
    static func unlockWithPINCodeAlert(
        biometricType: BiometricAuthenticationType?,
        action: @escaping (Bool) async -> Void,
    ) -> Alert {
        let message = switch biometricType {
        case .faceID:
            Localizations.pinRequireBioOrMasterPasswordRestart(Localizations.faceID)
        case .opticID:
            Localizations.pinRequireBioOrMasterPasswordRestart(Localizations.opticID)
        case .touchID:
            Localizations.pinRequireBioOrMasterPasswordRestart(Localizations.touchID)
        case .unknown:
            Localizations.pinRequireUnknownBiometricsOrMasterPasswordRestart
        case nil:
            Localizations.pinRequireMasterPasswordRestart
        }
        return Alert(
            title: Localizations.unlockWithPIN,
            message: message,
            alertActions: [
                AlertAction(title: Localizations.no, style: .cancel) { _ in
                    await action(false)
                },
                AlertAction(title: Localizations.yes, style: .default) { _ in
                    await action(true)
                },
            ],
        )
    }

    /// An alert asking the user to enter the verification code that was sent to their email.
    ///
    /// - Parameter completion: The action to occur when submit is tapped.
    /// - Returns: An alert asking the user to enter the verification code that was sent to their email.
    ///
    static func verificationCodePrompt(completion: @MainActor @escaping (String) async -> Void) -> Alert {
        Alert(
            title: Localizations.verificationCode,
            message: Localizations.enterTheVerificationCodeThatWasSentToYourEmail,
            alertActions: [
                AlertAction(
                    title: Localizations.submit,
                    style: .default,
                ) { _, alertTextFields in
                    guard let password = alertTextFields.first(where: { $0.id == "otp" })?.text else { return }
                    await completion(password)
                },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ],
            alertTextFields: [
                AlertTextField(
                    id: "otp",
                    autocapitalizationType: .none,
                    autocorrectionType: .no,
                    isSecureTextEntry: true,
                    keyboardType: .numberPad,
                ),
            ],
        )
    }

    /// An alert that asks if the user wants to navigate to the web vault in a browser.
    ///
    /// - Parameter action: The action taken if they select continue.
    /// - Returns: An alert that asks if the user wants to navigate to the web vault to leave a review.
    ///
    static func webVaultAlert(action: @escaping () -> Void) -> Alert {
        Alert(
            title: Localizations.continueToWebApp,
            message: Localizations.exploreMoreFeaturesOfYourBitwardenAccountOnTheWebApp,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.continue, style: .default) { _ in
                    action()
                },
            ],
        )
    }
}
