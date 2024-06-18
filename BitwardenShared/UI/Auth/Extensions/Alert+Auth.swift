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

    /// Display the options to log out of or lock the selected profile switcher item.
    ///
    /// - Parameters:
    ///   - item: The selected item from the profile switcher view.
    ///   - lockAction: The action to perform if the user chooses to lock the account.
    ///   - logoutAction: The action to perform if the user chooses to log out of the account.
    ///
    /// - Returns: An alert displaying the options for the item.
    ///
    static func accountOptions(
        _ item: ProfileSwitcherItem,
        hasNeverLock: Bool = false,
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
        if item.isUnlocked,
           !hasNeverLock {
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
            title: [item.email, item.webVault].joined(separator: "\n"),
            message: nil,
            preferredStyle: .actionSheet,
            alertActions: alertActions + [AlertAction(title: Localizations.cancel, style: .cancel)]
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

    /// An alert notifying the user that they have unassigned ciphers.
    ///
    /// - Parameters:
    ///   - action: The action taken if the user acknowledges.
    /// - Returns: An alert notififying the user that they have unassigned ciphers.
    ///
    static func unassignedCiphers(
        _ action: @escaping () async -> Void
    ) -> Alert {
        Alert(
            title: Localizations.notice,
            message: Localizations.organizationUnassignedItemsMessageUSEUDescriptionLong,
            alertActions: [
                AlertAction(title: Localizations.remindMeLater, style: .default),
                AlertAction(title: Localizations.ok, style: .default) { _ in
                    await action()
                },
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
            message: settingUp ? Localizations.setPINDescription : Localizations.verifyPIN,
            alertActions: [
                AlertAction(
                    title: Localizations.submit,
                    style: .default,
                    handler: { _, alertTextFields in
                        guard let pin = alertTextFields.first(where: { $0.id == "pin" })?.text else { return }
                        await completion(pin)
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
}
