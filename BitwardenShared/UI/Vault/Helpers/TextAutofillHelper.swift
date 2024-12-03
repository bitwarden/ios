import BitwardenSdk

// MARK: - TextAutofillHelper

/// Protocol that helps to autofill text for any cipher type.
/// Note: This is momentary until the UI/UX is improved in the Autofill text flow.
protocol TextAutofillHelper: AnyObject {
    /// Handles autofilling text to insert from a cipher by presenting options for the user
    /// to choose which field they want to use for autofilling text.
    /// - Parameter cipherView: The cipher to present options and get text to autofill.
    @MainActor
    func handleCipherForAutofill(cipherView: CipherView) async

    /// Sets the delegate to used with this helper.
    func setTextAutofillHelperDelegate(_ delegate: TextAutofillHelperDelegate)
}

// MARK: - TextAutofillHelperDelegate

/// A delegate to be used with the `TextAutofillHelper`.
@MainActor
protocol TextAutofillHelperDelegate: AnyObject {
    /// Completes the text request with some text to insert.
    @available(iOSApplicationExtension 18.0, *)
    func completeTextRequest(text: String)

    /// Shows the alert.
    ///
    /// - Parameters:
    ///   - alert: The alert to show.
    ///   - onDismissed: An optional closure that is called when the alert is dismissed.
    ///
    func showAlert(_ alert: Alert, onDismissed: (() -> Void)?)
}

@MainActor
extension TextAutofillHelperDelegate {
    /// Shows the alert.
    ///
    /// - Parameters:
    ///   - alert: The alert to show.
    ///   - onDismissed: An optional closure that is called when the alert is dismissed.
    ///
    func showAlert(_ alert: Alert) {
        showAlert(alert, onDismissed: nil)
    }
}

// MARK: - DefaultTextAutofillHelper

/// Default implementation of `TextAutofillHelper`.
@available(iOSApplicationExtension 18.0, *)
class DefaultTextAutofillHelper: TextAutofillHelper {
    // MARK: Properties

    /// The repository used by the application to manage auth data for the UI layer.
    private let authRepository: AuthRepository

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used to record and send events.
    private let eventService: EventService

    /// The delegate to used with this helper.
    private weak var textAutofillHelperDelegate: TextAutofillHelperDelegate?

    /// Helper to execute user verifications
    private var userVerificationHelper: UserVerificationHelper

    /// The repository used by the application to manage vault data for the UI layer.
    private let vaultRepository: VaultRepository

    // MARK: Initialization

    /// Initialize an `DefaultTextAutofillHelper`.
    ///
    /// - Parameters:
    ///   - authRepository: A delegate used to communicate with the autofill app extension.
    ///   - errorReporter: The coordinator that handles navigation.
    ///   - eventService: The services used by this processor.
    ///   - userVerificationHelper: Helper to execute user verifications.
    ///   - vaultRepository: The repository used by the application to manage vault data for the UI layer.
    ///
    init(
        authRepository: AuthRepository,
        errorReporter: ErrorReporter,
        eventService: EventService,
        userVerificationHelper: UserVerificationHelper,
        vaultRepository: VaultRepository
    ) {
        self.authRepository = authRepository
        self.errorReporter = errorReporter
        self.eventService = eventService
        self.userVerificationHelper = userVerificationHelper
        self.vaultRepository = vaultRepository
        self.userVerificationHelper.userVerificationDelegate = self
    }

    // MARK: Methods

    func handleCipherForAutofill(
        cipherView: CipherView
    ) async {
        do {
            if cipherView.reprompt == .password,
               try await authRepository.hasMasterPassword(),
               try await userVerificationHelper.verifyMasterPassword() != .verified {
                return
            }

            try await showOptionsForAutofill(cipherView: cipherView)
        } catch UserVerificationError.cancelled {
            // No-op
        } catch {
            errorReporter.log(error: error)
            textAutofillHelperDelegate?.showAlert(
                .defaultAlert(title: Localizations.anErrorHasOccurred)
            )
        }
    }

    /// Sets the delegate to used with this helper.
    func setTextAutofillHelperDelegate(_ delegate: TextAutofillHelperDelegate) {
        textAutofillHelperDelegate = delegate
    }

    // MARK: Private

    /// Completes the text autofill request with the specified value.
    /// - Parameters:
    ///   - localizedOption: The localized option selected.
    ///   - textToInsert: The value to be used to complete the request.
    private func completeTextAutofill(localizedOption: String, textToInsert: String) async {
        do {
            guard localizedOption != Localizations.totp else {
                let key = TOTPKeyModel(authenticatorKey: textToInsert)
                if let codeModel = try await vaultRepository.refreshTOTPCode(for: key).codeModel {
                    await textAutofillHelperDelegate?.completeTextRequest(text: codeModel.code)
                }
                return
            }
            await textAutofillHelperDelegate?.completeTextRequest(text: textToInsert)
        } catch {
            await textAutofillHelperDelegate?.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            errorReporter.log(error: error)
        }
    }

    /// Gets the autofill options for a card cipher for the user to choose from.
    /// - Parameter cipherView: The cipher the user selected.
    /// - Returns: The localized option title and the value to insert if that's selected.
    private func getAutofillOptionsForCard(
        cipherView: CipherView
    ) async throws -> [(
        localizedOption: String,
        textToInsert: String
    )] {
        guard let card = cipherView.card else {
            return []
        }
        var options: [(localizedOption: String, textToInsert: String)] = []
        if let name = card.cardholderName, !name.isEmpty {
            options.append((Localizations.cardholderName, name))
        }
        if let number = card.number, !number.isEmpty, cipherView.viewPassword {
            options.append((Localizations.number, number))
        }
        if let code = card.code, !code.isEmpty, cipherView.viewPassword {
            options.append((Localizations.securityCode, code))
        }
        return options
    }

    /// Gets the autofill options for an identity cipher for the user to choose from.
    /// - Parameter cipherView: The cipher the user selected.
    /// - Returns: The localized option title and the value to insert if that's selected.
    private func getAutofillOptionsForIdentity(
        cipherView: CipherView
    ) async throws -> [(
        localizedOption: String,
        textToInsert: String
    )] {
        guard let identity = cipherView.identity else {
            return []
        }
        var options: [(localizedOption: String, textToInsert: String)] = []
        if let firstName = identity.firstName, !firstName.isEmpty,
           let lastName = identity.lastName, !lastName.isEmpty {
            options.append((Localizations.fullName, "\(firstName) \(lastName)"))
        }
        if let ssn = identity.ssn, !ssn.isEmpty {
            options.append((Localizations.ssn, ssn))
        }
        if let passport = identity.passportNumber, !passport.isEmpty {
            options.append((Localizations.passportNumber, passport))
        }
        if let email = identity.email, !email.isEmpty {
            options.append((Localizations.email, email))
        }
        if let phone = identity.phone, !phone.isEmpty {
            options.append((Localizations.phone, phone))
        }
        return options
    }

    /// Gets the autofill options for a login cipher for the user to choose from.
    /// - Parameter cipherView: The cipher the user selected.
    /// - Returns: The localized option title and the value to insert if that's selected.
    private func getAutofillOptionsForLogin(
        cipherView: CipherView
    ) async throws -> [(
        localizedOption: String,
        textToInsert: String
    )] {
        guard let login = cipherView.login else {
            return []
        }
        var options: [(localizedOption: String, textToInsert: String)] = []
        if let username = login.username, !username.isEmpty {
            options.append((Localizations.username, username))
        }
        if let password = login.password, !password.isEmpty, cipherView.viewPassword {
            options.append((Localizations.password, password))
        }

        do {
            let disableAutoTotpCopy = try await vaultRepository.getDisableAutoTotpCopy()
            let accountHasPremium = try await vaultRepository.doesActiveAccountHavePremium()

            if !disableAutoTotpCopy, let totp = cipherView.login?.totp,
               cipherView.organizationUseTotp || accountHasPremium {
                // We can't calculate the TOTP code here because the user could take a while until they
                // choose the option and the code could expire by then so it needs to be calculated
                // after the user chooses this option.
                options.append((Localizations.totp, totp))
            }
        } catch {
            errorReporter.log(error: error)
        }

        return options
    }

    /// Gets the autofill options for a secure note cipher for the user to choose from.
    /// - Parameter cipherView: The cipher the user selected.
    /// - Returns: The localized option title and the value to insert if that's selected.
    private func getAutofillOptionsForSecureNote(
        cipherView: CipherView
    ) async throws -> [(
        localizedOption: String,
        textToInsert: String
    )] {
        guard cipherView.secureNote != nil else {
            return []
        }
        var options: [(localizedOption: String, textToInsert: String)] = []
        if let notes = cipherView.notes, !notes.isEmpty {
            options.append((Localizations.notes, notes))
        }
        return options
    }

    /// Gets the autofill options for an SSH key cipher for the user to choose from.
    /// - Parameter cipherView: The cipher the user selected.
    /// - Returns: The localized option title and the value to insert if that's selected.
    private func getAutofillOptionsForSSHKey(
        cipherView: CipherView
    ) async throws -> [(
        localizedOption: String,
        textToInsert: String
    )] {
        guard let sshKey = cipherView.sshKey else {
            return []
        }
        var options: [(localizedOption: String, textToInsert: String)] = []
        if !sshKey.privateKey.isEmpty, cipherView.viewPassword {
            options.append((Localizations.privateKey, sshKey.privateKey))
        }
        if !sshKey.publicKey.isEmpty {
            options.append((Localizations.publicKey, sshKey.publicKey))
        }
        if !sshKey.fingerprint.isEmpty {
            options.append((Localizations.fingerprint, sshKey.fingerprint))
        }
        return options
    }

    /// Shows the custom fields for the user to choose from to autofill.
    /// - Parameters:
    ///   - customFields: The custom fields to show the options.
    private func showCustomFieldsOptionsForAutofill(_ customFields: [CustomFieldState]) async {
        let alertActions: [AlertAction] = customFields.compactMap { field in
            guard let name = field.name, let value = field.value else {
                return nil
            }

            return AlertAction(
                title: name,
                style: .default
            ) { [weak self] _, _ in
                guard let self else { return }
                await completeTextAutofill(
                    localizedOption: name,
                    textToInsert: value
                )
            }
        }
        await textAutofillHelperDelegate?.showAlert(
            Alert(
                title: Localizations.autofill,
                message: nil,
                preferredStyle: .actionSheet,
                alertActions: alertActions + [AlertAction(title: Localizations.cancel, style: .cancel)]
            )
        )
    }

    /// Shows the options for the cipher for the user to select the field to autofill.
    /// - Parameter cipherView: The cipher selected by the user.
    private func showOptionsForAutofill(cipherView: CipherView) async throws { // swiftlint:disable:this function_body_length line_length
        let options = switch cipherView.type {
        case .card:
            try await getAutofillOptionsForCard(cipherView: cipherView)
        case .identity:
            try await getAutofillOptionsForIdentity(cipherView: cipherView)
        case .login:
            try await getAutofillOptionsForLogin(cipherView: cipherView)
        case .secureNote:
            try await getAutofillOptionsForSecureNote(cipherView: cipherView)
        case .sshKey:
            try await getAutofillOptionsForSSHKey(cipherView: cipherView)
        }

        var alertActions = options.map { option in
            AlertAction(
                title: option.localizedOption,
                style: .default
            ) { [weak self] _, _ in
                guard let self else { return }
                await completeTextAutofill(
                    localizedOption: option.localizedOption,
                    textToInsert: option.textToInsert
                )
            }
        }
        let availableCustomFields = cipherView.customFields.filter { field in
            field.type != .hidden || cipherView.viewPassword
        }
        if !availableCustomFields.isEmpty {
            alertActions.append(AlertAction(
                title: Localizations.customFields,
                style: .default
            ) { [weak self] _, _ in
                guard let self else { return }
                await showCustomFieldsOptionsForAutofill(availableCustomFields)
            })
        }

        guard !alertActions.isEmpty else {
            await textAutofillHelperDelegate?.showAlert(.defaultAlert(
                title: cipherView.name,
                message: Localizations.nothingAvailableToAutofill
            ))
            return
        }

        await textAutofillHelperDelegate?.showAlert(
            Alert(
                title: Localizations.autofill,
                message: nil,
                preferredStyle: .actionSheet,
                alertActions: alertActions + [AlertAction(title: Localizations.cancel, style: .cancel)]
            )
        )
    }
}

// MARK: - UserVerificationDelegate

@available(iOSApplicationExtension 18.0, *)
extension DefaultTextAutofillHelper: UserVerificationDelegate {
    func showAlert(_ alert: Alert) {
        textAutofillHelperDelegate?.showAlert(alert)
    }

    func showAlert(_ alert: Alert, onDismissed: (() -> Void)?) {
        textAutofillHelperDelegate?.showAlert(alert, onDismissed: onDismissed)
    }
}

// MARK: NoOpTextAutofillHelper

/// Helper to be used on iOS less than 18.0 given that we don't have autofilling text feature available.
class NoOpTextAutofillHelper: TextAutofillHelper {
    func handleCipherForAutofill(cipherView: BitwardenSdk.CipherView) async {
        // No-op
    }

    /// Sets the delegate to used with this helper.
    func setTextAutofillHelperDelegate(_ delegate: TextAutofillHelperDelegate) {
        // No-op
    }
} // swiftlint:disable:this file_length
