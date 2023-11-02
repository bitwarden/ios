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
}

// MARK: - DefaultGeneratorRepository

/// A default implementation of a `GeneratorRepository`.
///
class DefaultGeneratorRepository {
    // MARK: Properties

    /// The client used for generating passwords and passphrases.
    let clientGenerators: ClientGeneratorsProtocol

    // MARK: Initialization

    /// Initialize a `DefaultGeneratorRepository`
    ///
    /// - Parameter clientGenerators: The client used for generating passwords and passphrases.
    ///
    init(clientGenerators: ClientGeneratorsProtocol) {
        self.clientGenerators = clientGenerators
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
}
