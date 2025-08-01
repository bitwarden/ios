import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - Alert+Auth

extension Alert {
    // MARK: - PasswordStrengthAlertType

    /// An enumeration of password strength related alert types.
    ///
    enum PasswordStrengthAlertType: CaseIterable {
        /// An exposed but strong password.
        case exposedStrong

        /// An exposed and weak password.
        case exposedWeak

        /// A weak password unchecked against breaches.
        case weak

        /// The title of the alert.
        var title: String {
            switch self {
            case .exposedStrong:
                Localizations.exposedMasterPassword
            case .exposedWeak:
                Localizations.weakAndExposedMasterPassword
            case .weak:
                Localizations.weakMasterPassword
            }
        }

        /// The alert's message.
        var message: String {
            switch self {
            case .exposedStrong:
                Localizations.passwordFoundInADataBreachAlertDescription
            case .exposedWeak:
                Localizations.weakPasswordIdentifiedAndFoundInADataBreachAlertDescription
            case .weak:
                Localizations.weakPasswordIdentifiedUseAStrongPasswordToProtectYourAccount
            }
        }

        // MARK: Initialization

        /// Initializes a `PasswordStrengthAlertType`.
        ///
        /// - Parameters:
        ///   - isBreached: Whether the password is breached.
        ///   - isWeak: Whether the password is weak.
        ///
        init(isBreached: Bool, isWeak: Bool) {
            switch (isBreached, isWeak) {
            case (true, true):
                self = .exposedWeak
            case (true, false):
                self = .exposedStrong
            default:
                self = .weak
            }
        }
    }

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

    /// Display the options to log out of, lock, or remove the selected profile switcher item.
    ///
    /// - Parameters:
    ///   - item: The selected item from the profile switcher view.
    ///   - lockAction: The action to perform if the user chooses to lock the account.
    ///   - logoutAction: The action to perform if the user chooses to log out of the account.
    ///   - removeAccountAction: The action to perform if the user chooses to remove the account.
    ///
    /// - Returns: An alert displaying the options for the item.
    ///
    static func accountOptions(
        _ item: ProfileSwitcherItem,
        lockAction: @escaping () async -> Void,
        logoutAction: @escaping () async -> Void,
        removeAccountAction: @escaping () async -> Void
    ) -> Alert {
        var alertActions = [AlertAction]()

        if item.isUnlocked, item.canBeLocked {
            alertActions.append(
                AlertAction(
                    title: Localizations.lock,
                    style: .default,
                    handler: { _, _ in await lockAction() }
                )
            )
        }

        if item.isLoggedOut {
            alertActions.append(
                AlertAction(
                    title: Localizations.removeAccount,
                    style: .default,
                    handler: { _, _ in await removeAccountAction() }
                )
            )
        } else {
            alertActions.append(
                AlertAction(
                    title: Localizations.logOut,
                    style: .default,
                    handler: { _, _ in await logoutAction() }
                )
            )
        }

        return Alert(
            title: [item.email, item.webVault].joined(separator: "\n"),
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: alertActions + [AlertAction(title: Localizations.cancel, style: .cancel)]
        )
    }

    /// An alert notifying the user that they need to migrate their encryption key.
    ///
    /// - Returns: An alert notifying the user that they need to migrate their encryption key.
    ///
    static func encryptionKeyMigrationRequiredAlert(
        environmentUrl: String,
    ) -> Alert {
        Alert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.thisAccountWillSoonBeDeletedLogInAtXToContinueUsingBitwarden(environmentUrl),
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        )
    }

    /// An alert notifying the user that unlocking the user's vault may fail in an app extension
    /// because their KDF settings use too much memory.
    ///
    /// - Parameter continueAction: A closure containing the action to take if the user wants to
    ///     continue despite the warning.
    /// - Returns: An alert notifying the user that unlocking the user's vault may fail in an app
    ///     extension because their KDF settings use too much memory.
    ///
    static func extensionKdfMemoryWarning(continueAction: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.warning,
            message: Localizations.unlockingMayFailDueToInsufficientMemoryDecreaseYourKDFMemorySettingsToResolve,
            alertActions: [
                AlertAction(title: Localizations.continue, style: .default) { _ in
                    await continueAction()
                },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ]
        )
    }

    /// An alert that is displayed to confirm the user wants to leave the organization
    ///
    /// - Parameter action: An action to perform when the user taps `Yes`, to confirm leave organization.
    /// - Returns: An alert that is displayed to confirm the user wants to leave the organization.
    ///
    static func leaveOrganizationConfirmation(
        orgName: String,
        action: @escaping () async -> Void
    ) -> Alert {
        Alert(
            title: Localizations.leaveOrganization,
            message: Localizations.leaveOrganizationName(orgName),
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _ in await action() },
                AlertAction(title: Localizations.cancel, style: .cancel),
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

    /// An alert that is displayed to confirm the user wants to log out of the account.
    ///
    /// - Parameters:
    ///   - profile: The profile switcher item to log out.
    ///   - action: An action to perform when the user taps `Yes`, to confirm logout.
    /// - Returns: An alert that is displayed to confirm the user wants to log out of the account.
    ///
    static func logoutConfirmation(
        _ profile: ProfileSwitcherItem,
        action: @escaping () async -> Void
    ) -> Alert {
        Alert(
            title: Localizations.logOut,
            message: Localizations.logoutConfirmation + "\n\n"
                + [profile.email, profile.webVault].joined(separator: "\n"),
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _ in await action() },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ]
        )
    }

    /// An alert that is displayed to confirm the key connector domain.
    ///
    /// - Parameter action: An action to perform when the user taps `Yes`, to confirm the domain.
    /// - Returns: An alert that is displayed to confirm the key connector domain.
    static func keyConnectorConfirmation(
        keyConnectorUrl: URL,
        action: @escaping () async -> Void
    ) -> Alert {
        Alert(
            title: Localizations.confirmKeyConnectorDomain,
            message: Localizations.keyConnectorConfirmDomainWithAdmin(keyConnectorUrl),
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _ in await action() },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ]
        )
    }

    /// Returns an alert notifying the user that their master password is invalid.
    ///
    /// - Returns: An alert notifying the user that their master password is invalid.
    ///
    static func masterPasswordInvalid() -> Alert {
        defaultAlert(
            title: Localizations.masterPasswordPolicyValidationTitle,
            message: Localizations.masterPasswordPolicyValidationMessage
        )
    }

    /// An alert notifying the user that their password has been exposed and or is weak.
    ///
    /// - Parameters:
    ///   - alertType: The type of alert to show.
    ///   - action: The action taken if the user opts to use the password anyways.
    ///
    /// - Returns: An alert notifying the user that their password has been exposed and or is weak.
    ///
    static func passwordStrengthAlert(
        _ alertType: PasswordStrengthAlertType,
        _ action: @escaping () async -> Void
    ) -> Alert {
        Alert(
            title: alertType.title,
            message: alertType.message,
            alertActions: [
                AlertAction(title: Localizations.no, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in
                    await action()
                },
            ]
        )
    }

    /// An alert that is displayed to confirm the user wants to remove the account.
    ///
    /// - Parameters:
    ///   - profile: The profile switcher item to remove.
    ///   - action: An action to perform when the user taps `Yes`, to confirm removing the account.
    /// - Returns: An alert that is displayed to confirm the user wants to remove the account.
    ///
    static func removeAccountConfirmation(
        _ profile: ProfileSwitcherItem,
        action: @escaping () async -> Void
    ) -> Alert {
        Alert(
            title: Localizations.removeAccount,
            message: Localizations.removeAccountConfirmation + "\n\n"
                + [profile.email, profile.webVault].joined(separator: "\n"),
            alertActions: [
                AlertAction(title: Localizations.yes, style: .default) { _ in await action() },
                AlertAction(title: Localizations.cancel, style: .cancel),
            ]
        )
    }

    /// An alert confirming that the user wants to finish setting up autofill later in settings.
    ///
    /// - Parameter action: The action taken when the user taps on Confirm to finish setting up
    ///     autofill later in settings.
    /// - Returns: An alert confirming that the user wants to finish setting up autofill let in settings.
    ///
    static func setUpAutoFillLater(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.turnOnAutoFillLaterQuestion,
            message: Localizations.youCanReturnToCompleteThisStepAnytimeInSettings,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.confirm, style: .default) { _ in
                    await action()
                },
            ]
        )
    }

    /// An alert confirming that the user wants to finish setting up their vault unlock methods
    /// later in settings.
    ///
    /// - Parameter action: The action taken when the user taps on Confirm to finish setting up
    ///     their vault unlock methods later in settings.
    /// - Returns: An alert confirming that the user wants to finish setting up their vault unlock
    ///     methods later in settings.
    ///
    static func setUpUnlockMethodLater(action: @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.setUpLaterQuestion,
            message: Localizations.youCanFinishSetupUnlockAnytimeDescriptionLong,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.confirm, style: .default) { _ in
                    await action()
                },
            ]
        )
    }

    /// An alert asking the user if they want to switch to the already existing account when adding
    /// a new account.
    ///
    /// - Parameter action: The action taken if the user wants to switch to the existing account.
    /// - Returns: An alert asking the user if they want to switch to the already existing account
    ///     when adding a new account.
    ///
    static func switchToExistingAccount(
        action: @escaping () async -> Void
    ) -> Alert {
        Alert(
            title: Localizations.accountAlreadyAdded,
            message: Localizations.switchToAlreadyAddedAccountConfirmation,
            alertActions: [
                AlertAction(title: Localizations.cancel, style: .cancel),
                AlertAction(title: Localizations.yes, style: .default) { _ in await action() },
            ]
        )
    }

    /// An alert that prompts the user to enter their PIN.
    /// - Parameters:
    ///   - completion: The code block that's executed when the user has entered their pin.
    ///   - onCancelled: A block that is executed when the user interacts with the "Cancel" button.
    ///   - settingUp: Whether the message displayed to the user is to set or verify a pin
    /// - Returns: An alert that prompts the user to enter their PIN.
    static func enterPINCode(
        onCancelled: (() -> Void)? = nil,
        settingUp: Bool = true,
        completion: @MainActor @escaping (String) async -> Void
    ) -> Alert {
        Alert(
            title: Localizations.enterPIN,
            message: settingUp
                ? Localizations.yourPINMustBeAtLeastXCharactersDescriptionLong(Constants.minimumPinLength)
                : Localizations.verifyPIN,
            alertActions: [
                AlertAction(
                    title: Localizations.submit,
                    style: .default,
                    handler: { _, alertTextFields in
                        guard let pin = alertTextFields.first(where: { $0.id == "pin" })?.text else { return }
                        await completion(pin)
                    },
                    shouldEnableAction: { textFields in
                        guard let pin = textFields.first(where: { $0.id == "pin" })?.text else { return false }
                        return pin.count >= Constants.minimumPinLength
                    }
                ),
                AlertAction(title: Localizations.cancel, style: .cancel, handler: { _, _ in
                    onCancelled?()
                }),
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
} // swiftlint:disable:this file_length
