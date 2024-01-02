// MARK: - Alert

extension Alert {
    // MARK: Static Properties

    /// An invalid email error alert.
    ///
    static var invalidEmail: Alert {
        Alert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.invalidEmail,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        )
    }

    /// An alert to show when password confirmation is incorrect.
    ///
    static var passwordsDontMatch: Alert {
        Alert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.masterPasswordConfirmationValMessage,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        )
    }

    /// An alert to show when the password does not meet the minimum length requirement.
    ///
    static var passwordIsTooShort: Alert {
        Alert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.masterPasswordLengthValMessageX(Constants.minimumPasswordCharacters),
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        )
    }

    /// An alert to show when a required field was left empty.
    ///
    /// - Parameter fieldName: The name of the field that was left empty.
    ///
    /// - Returns: an alert shown when a required field was left empty.
    ///
    static func validationFieldRequired(fieldName: String) -> Alert {
        Alert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.validationFieldRequired(fieldName),
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        )
    }

    // MARK: Static Methods

    /// An confirmation alert to show when the user wants to delete cipher item .
    ///
    /// - Parameter completion: A block that is executed when the user interacts with the "yes" button.
    ///
    static func deleteCipherConfirmation(completion: @MainActor @escaping () async -> Void) -> Alert {
        Alert(
            title: Localizations.doYouReallyWantToSoftDeleteCipher,
            message: nil,
            alertActions: [
                AlertAction(
                    title: Localizations.yes,
                    style: .default,
                    handler: { _ in
                        await completion()
                    }
                ),
                AlertAction(title: Localizations.cancel, style: .cancel),
            ]
        )
    }

    /// An alert to show when the user needs to confirm their master password.
    ///
    /// - Parameter completion: A block that is executed when the user interacts with the "Submit" button.
    ///
    static func masterPasswordPrompt(completion: @MainActor @escaping (String) async -> Void) -> Alert {
        Alert(
            title: Localizations.passwordConfirmation,
            message: Localizations.passwordConfirmationDesc,
            alertActions: [
                AlertAction(
                    title: Localizations.submit,
                    style: .default,
                    handler: { _, alertTextFields in
                        guard let password = alertTextFields.first(where: { $0.id == "password" })?.text else { return }
                        await completion(password)
                    }
                ),
                AlertAction(title: Localizations.cancel, style: .cancel),
            ],
            alertTextFields: [
                AlertTextField(
                    id: "password",
                    autocapitalizationType: .none,
                    autocorrectionType: .no,
                    isSecureTextEntry: true
                ),
            ]
        )
    }
}
