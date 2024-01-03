import BitwardenSdk
import Combine

/// A protocol for a `GeneratorRepository` which manages access to the data needed by the UI layer.
///
protocol GeneratorRepository: AnyObject {
    // MARK: Password History

    /// Adds a generated password to the user's password history.
    ///
    /// - Parameter passwordHistory: The generated password to add.
    ///
    func addPasswordHistory(_ passwordHistory: PasswordHistoryView) async throws

    /// Removes all of the entries from the user's password history.
    ///
    func clearPasswordHistory() async throws

    /// A publisher for the user's password history items.
    ///
    /// - Returns: A publisher for the user's password history items which will be notified as the
    ///     data changes.
    ///
    func passwordHistoryPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[PasswordHistoryView], Error>>

    // MARK: Generator

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

    /// Generates a username based on the username settings.
    ///
    /// - Parameter settings: The settings used to generate the username.
    /// - Returns: The generated username.
    ///
    func generateUsername(settings: UsernameGeneratorRequest) async throws -> String

    /// Generates a plus-addressed email based on the username generation options.
    ///
    /// - Returns: The generated plus-addressed email.
    ///
    func generateUsernamePlusAddressedEmail(email: String) async throws -> String

    /// Gets the password generation options for the active account.
    ///
    /// - Returns: The password generation options for the account.
    ///
    func getPasswordGenerationOptions() async throws -> PasswordGenerationOptions

    /// Gets the username generation options for the active account.
    ///
    /// - Returns: The username generation options for the account.
    ///
    func getUsernameGenerationOptions() async throws -> UsernameGenerationOptions

    /// Sets the password generation options for the active account.
    ///
    /// - Parameter options: The user's password generation options.
    ///
    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions) async throws

    /// Sets the username generation options for the active account.
    ///
    /// - Parameter options: The user's username generation options.
    ///
    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions) async throws
}

// MARK: - DefaultGeneratorRepository

/// A default implementation of a `GeneratorRepository`.
///
class DefaultGeneratorRepository {
    // MARK: Properties

    /// The client used for generating passwords and passphrases.
    let clientGenerators: ClientGeneratorsProtocol

    /// The client used by the application to handle vault encryption and decryption tasks.
    let clientVaultService: ClientVaultService

    /// The service used to handle cryptographic operations.
    let cryptoService: CryptoService

    /// The data store that handles performing data requests for the generator.
    let dataStore: GeneratorDataStore

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultGeneratorRepository`
    ///
    /// - Parameters:
    ///   - clientGenerators: The client used for generating passwords and passphrases.
    ///   - clientVaultService: The client used by the application to handle vault encryption and
    ///     decryption tasks.
    ///   - cryptoService: The service used to handle cryptographic operations.
    ///   - dataStore: The data store that handles performing data requests for the generator.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        clientGenerators: ClientGeneratorsProtocol,
        clientVaultService: ClientVaultService,
        cryptoService: CryptoService = DefaultCryptoService(randomNumberGenerator: SecureRandomNumberGenerator()),
        dataStore: GeneratorDataStore,
        stateService: StateService
    ) {
        self.clientGenerators = clientGenerators
        self.clientVaultService = clientVaultService
        self.cryptoService = cryptoService
        self.dataStore = dataStore
        self.stateService = stateService
    }

    // MARK: Private

    /// Determines if the password is a duplicate of the most recent password in the history.
    ///
    /// - Parameters:
    ///   - passwordHistory: The password history item to check if it's a duplicate.
    ///   - userId: The ID of the user associated with the password.
    /// - Returns: Whether the password is a duplicate of the most recent password in the history.
    ///
    private func isDuplicateOfMostRecent(passwordHistory: PasswordHistoryView, userId: String) async throws -> Bool {
        guard let mostRecentEncrypted = try? await dataStore.fetchPasswordHistoryMostRecent(userId: userId) else {
            return false
        }
        let mostRecent = try await clientVaultService.passwordHistory().decryptList(list: [mostRecentEncrypted]).first
        return mostRecent?.password == passwordHistory.password
    }
}

// MARK: GeneratorRepository

extension DefaultGeneratorRepository: GeneratorRepository {
    // MARK: Password History

    func addPasswordHistory(_ passwordHistory: PasswordHistoryView) async throws {
        let userId = try await stateService.getActiveAccountId()

        // Prevent adding a duplicate at the top of the list.
        guard try await !isDuplicateOfMostRecent(passwordHistory: passwordHistory, userId: userId) else { return }

        let encryptedPasswordHistory = try await clientVaultService.passwordHistory().encrypt(
            passwordHistory: passwordHistory
        )
        try await dataStore.insertPasswordHistory(userId: userId, passwordHistory: encryptedPasswordHistory)

        // Remove any passwords past the max limit.
        try await dataStore.deletePasswordHistoryPastLimit(userId: userId, limit: Constants.maxPasswordsInHistory)
    }

    func clearPasswordHistory() async throws {
        let userId = try await stateService.getActiveAccountId()
        try await dataStore.deleteAllPasswordHistory(userId: userId)
    }

    func passwordHistoryPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[PasswordHistoryView], Error>> {
        let userId = try await stateService.getActiveAccountId()
        return dataStore.passwordHistoryPublisher(userId: userId)
            .asyncTryMap { passwordHistory in
                try await self.clientVaultService.passwordHistory()
                    .decryptList(list: passwordHistory)
            }
            .eraseToAnyPublisher()
            .values
    }

    // MARK: Generator

    func generatePassphrase(settings: PassphraseGeneratorRequest) async throws -> String {
        try await clientGenerators.passphrase(settings: settings)
    }

    func generatePassword(settings: PasswordGeneratorRequest) async throws -> String {
        try await clientGenerators.password(settings: settings)
    }

    func generateUsername(settings: UsernameGeneratorRequest) async throws -> String {
        try await clientGenerators.username(settings: settings)
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

    func getPasswordGenerationOptions() async throws -> PasswordGenerationOptions {
        try await stateService.getPasswordGenerationOptions() ?? PasswordGenerationOptions()
    }

    func getUsernameGenerationOptions() async throws -> UsernameGenerationOptions {
        var options = try await stateService.getUsernameGenerationOptions() ?? UsernameGenerationOptions()
        if options.plusAddressedEmail.isEmptyOrNil {
            options.plusAddressedEmail = try? await stateService.getActiveAccount().profile.email
        }
        return options
    }

    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions) async throws {
        try await stateService.setPasswordGenerationOptions(options)
    }

    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions) async throws {
        try await stateService.setUsernameGenerationOptions(options)
    }
}
