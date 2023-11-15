import BitwardenSdk

/// A protocol for a `GeneratorRepository` which manages access to the data needed by the UI layer.
///
protocol GeneratorRepository: AnyObject {
    /// Generates a passphrase based on the passphrase settings.
    ///
    /// - Parameter settings: The settings used to generate the passphrase.
    /// - Returns: The generated passphrase.
    ///
    func generatePassphrase(settings: PassphraseGeneratorRequest) async throws -> String

    /// Generates a password based on the password settings.
    ///
    /// - Parameter settings: The settings used to generate the password.
    /// - Returns: The generated password.
    ///
    func generatePassword(settings: PasswordGeneratorRequest) async throws -> String

    /// Generates a plus-addressed email based on the username generation options.
    ///
    /// - Returns: The generated plus-addressed email.
    ///
    func generateUsernamePlusAddressedEmail(email: String) async throws -> String

    /// Gets the password generation options for the active account.
    ///
    /// - Returns: The password generation options for the account.
    ///
    func getPasswordGenerationOptions() async -> PasswordGenerationOptions

    /// Sets the password generation options for the active account.
    ///
    /// - Parameter options: The user's password generation options.
    ///
    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions) async throws
}

// MARK: - DefaultGeneratorRepository

/// A default implementation of a `GeneratorRepository`.
///
class DefaultGeneratorRepository {
    // MARK: Properties

    /// The client used for generating passwords and passphrases.
    let clientGenerators: ClientGeneratorsProtocol

    /// The service used to handle cryptographic operations.
    let cryptoService: CryptoService

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultGeneratorRepository`
    ///
    /// - Parameters:
    ///   - clientGenerators: The client used for generating passwords and passphrases.
    ///   - cryptoService: The service used to handle cryptographic operations.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        clientGenerators: ClientGeneratorsProtocol,
        cryptoService: CryptoService = DefaultCryptoService(randomNumberGenerator: SecureRandomNumberGenerator()),
        stateService: StateService
    ) {
        self.clientGenerators = clientGenerators
        self.cryptoService = cryptoService
        self.stateService = stateService
    }
}

// MARK: GeneratorRepository

extension DefaultGeneratorRepository: GeneratorRepository {
    func generatePassphrase(settings: PassphraseGeneratorRequest) async throws -> String {
        try await clientGenerators.passphrase(settings: settings)
    }

    func generatePassword(settings: PasswordGeneratorRequest) async throws -> String {
        try await clientGenerators.password(settings: settings)
    }

    func generateUsernamePlusAddressedEmail(email: String) async throws -> String {
        guard email.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else {
            return Constants.defaultGeneratedUsername
        }

        guard let atIndex = email.firstIndex(of: "@"),
              // Ensure '@' symbol isn't the first or last character.
              atIndex > email.startIndex,
              atIndex < email.index(before: email.endIndex) else {
            return email
        }

        let randomString = try cryptoService.randomString(length: 8)

        var email = email
        email.insert(contentsOf: "+\(randomString)", at: atIndex)
        return email
    }

    func getPasswordGenerationOptions() async -> PasswordGenerationOptions {
        await stateService.getPasswordGenerationOptions() ?? PasswordGenerationOptions()
    }

    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions) async throws {
        try await stateService.setPasswordGenerationOptions(options)
    }
}
