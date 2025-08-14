import BitwardenKit
import BitwardenResources
import BitwardenSdk

/// Protocol for a helper that is used to get the options available for autofilling.
protocol TextAutofillOptionsHelper {
    /// Gets the autofill options for a cipher for the user to choose from.
    /// - Parameter cipherView: The cipher the user selected.
    /// - Returns: The localized option title and the value to insert if that's selected.
    func getTextAutofillOptions(cipherView: CipherView) async -> [(
        localizedOption: String,
        textToInsert: String
    )]
}

// MARK: - CardTextAutofillOptionsHelper

/// `TextAutofillOptionsHelper` implementation for Card.
struct CardTextAutofillOptionsHelper: TextAutofillOptionsHelper {
    func getTextAutofillOptions(cipherView: CipherView) async -> [(localizedOption: String, textToInsert: String)] {
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
}

// MARK: - CardTextAutofillOptionsHelper

/// `TextAutofillOptionsHelper` implementation for Identity.
struct IdentityTextAutofillOptionsHelper: TextAutofillOptionsHelper {
    func getTextAutofillOptions(cipherView: CipherView) async -> [(localizedOption: String, textToInsert: String)] {
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
}

// MARK: - LoginTextAutofillOptionsHelper

/// `TextAutofillOptionsHelper` implementation for Login.
struct LoginTextAutofillOptionsHelper: TextAutofillOptionsHelper {
    // MARK: Properties

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The repository used by the application to manage vault data for the UI layer.
    let vaultRepository: VaultRepository

    // MARK: Methods

    func getTextAutofillOptions(cipherView: CipherView) async -> [(localizedOption: String, textToInsert: String)] {
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
            if let totp = try await vaultRepository.getTOTPKeyIfAllowedToCopy(cipher: cipherView) {
                // We can't calculate the TOTP code here because the user could take a while until they
                // choose the option and the code could expire by then so it needs to be calculated
                // after the user chooses this option.
                options.append((Localizations.verificationCode, totp))
            }
        } catch {
            errorReporter.log(error: error)
        }

        return options
    }
}

// MARK: - SecureNoteTextAutofillOptionsHelper

/// `TextAutofillOptionsHelper` implementation for Secure Note.
struct SecureNoteTextAutofillOptionsHelper: TextAutofillOptionsHelper {
    func getTextAutofillOptions(cipherView: CipherView) -> [(localizedOption: String, textToInsert: String)] {
        guard cipherView.secureNote != nil else {
            return []
        }
        var options: [(localizedOption: String, textToInsert: String)] = []
        if let notes = cipherView.notes, !notes.isEmpty {
            options.append((Localizations.notes, notes))
        }
        return options
    }
}

// MARK: - SSHKeyTextAutofillOptionsHelper

/// `TextAutofillOptionsHelper` implementation for SSH Key.
struct SSHKeyTextAutofillOptionsHelper: TextAutofillOptionsHelper {
    func getTextAutofillOptions(cipherView: CipherView) -> [(localizedOption: String, textToInsert: String)] {
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
}
