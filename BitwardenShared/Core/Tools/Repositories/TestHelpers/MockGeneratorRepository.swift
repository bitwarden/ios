import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockGeneratorRepository: GeneratorRepository {
    var addPasswordHistoryCalled = false

    var clearPasswordHistoryCalled = false
    var clearPasswordHistoryResult: Result<Void, Error> = .success(())

    var passwordHistorySubject = CurrentValueSubject<[PasswordHistoryView], Error>([])

    var masterPasswordGeneratorCalled = false
    var masterPasswordGeneratorResult: Result<String, Error> = .success("MASTER_PASSWORD")

    var passphraseGeneratorRequest: PassphraseGeneratorRequest?
    var passphraseResult: Result<String, Error> = .success("PASSPHRASE")

    var passwordGeneratorRequest: PasswordGeneratorRequest?
    var passwordResult: Result<String, Error> = .success("PASSWORD")

    var passwordRulesRequestRules: String?
    var passwordRulesRequestResult: PasswordGeneratorRequest? = PasswordGeneratorRequest(
        lowercase: true,
        uppercase: true,
        numbers: true,
        special: false,
        length: 14,
        avoidAmbiguous: false,
        minLowercase: nil,
        minUppercase: nil,
        minNumber: nil,
        minSpecial: nil,
    )

    var usernameGeneratorRequest: UsernameGeneratorRequest?
    var usernameResult: Result<String, Error> = .success("USERNAME")

    // swiftlint:disable identifier_name
    var getEffectivePasswordGenerationOptionsCalled = false
    var getEffectivePasswordGenerationOptionsRules: String?
    var getEffectivePasswordGenerationOptionsIsPolicyInEffect = false
    // swiftlint:enable identifier_name

    var getPasswordGenerationOptionsCalled = false
    var getPasswordGenerationOptionsResult: Result<PasswordGenerationOptions, Error> =
        .success(PasswordGenerationOptions())
    var passwordGenerationOptions = PasswordGenerationOptions()
    var setPasswordGenerationOptionsResult: Result<Void, Error> = .success(())

    var getUsernameGenerationOptionsCalled = false
    var getUsernameGenerationOptionsResult: Result<UsernameGenerationOptions, Error> =
        .success(UsernameGenerationOptions())
    var usernameGenerationOptions = UsernameGenerationOptions()
    var setUsernameGenerationOptionsResult: Result<Void, Error> = .success(())

    var usernamePlusAddressEmail: String?
    var usernamePlusAddressEmailResult: Result<String, Error> = .success("user+abcd0123@bitwarden.com")

    // MARK: Password History

    func addPasswordHistory(_ passwordHistory: PasswordHistoryView) async throws {
        addPasswordHistoryCalled = true
        passwordHistorySubject.value.insert(passwordHistory, at: 0)
    }

    func clearPasswordHistory() async throws {
        clearPasswordHistoryCalled = true
        passwordHistorySubject.value.removeAll()
        try clearPasswordHistoryResult.get()
    }

    func passwordHistoryPublisher() -> AsyncThrowingPublisher<AnyPublisher<[PasswordHistoryView], Error>> {
        passwordHistorySubject.eraseToAnyPublisher().values
    }

    // MARK: Generator

    func generateMasterPassword() async throws -> String {
        masterPasswordGeneratorCalled = true
        return try masterPasswordGeneratorResult.get()
    }

    func generatePassphrase(settings: PassphraseGeneratorRequest, isPreAuth: Bool) async throws -> String {
        passphraseGeneratorRequest = settings
        return try passphraseResult.get()
    }

    func generatePassword(settings: PasswordGeneratorRequest) async throws -> String {
        passwordGeneratorRequest = settings
        return try passwordResult.get()
    }

    func passwordRulesRequest(rules: String) async -> PasswordGeneratorRequest? {
        passwordRulesRequestRules = rules
        return passwordRulesRequestResult
    }

    func generateUsername(settings: UsernameGeneratorRequest) async throws -> String {
        usernameGeneratorRequest = settings
        return try usernameResult.get()
    }

    func generateUsernamePlusAddressedEmail(email: String) async throws -> String {
        usernamePlusAddressEmail = email
        return try usernamePlusAddressEmailResult.get()
    }

    func getEffectivePasswordGenerationOptions(
        rules: String?,
    ) async throws -> (options: PasswordGenerationOptions, isPolicyInEffect: Bool) {
        defer { getEffectivePasswordGenerationOptionsCalled = true }
        getEffectivePasswordGenerationOptionsRules = rules
        let options = try await getPasswordGenerationOptions()
        return (options, getEffectivePasswordGenerationOptionsIsPolicyInEffect)
    }

    func getPasswordGenerationOptions() async throws -> PasswordGenerationOptions {
        defer { getPasswordGenerationOptionsCalled = true }
        return try getPasswordGenerationOptionsResult.get()
    }

    func getUsernameGenerationOptions() async throws -> UsernameGenerationOptions {
        defer { getUsernameGenerationOptionsCalled = true }
        return try getUsernameGenerationOptionsResult.get()
    }

    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions) async throws {
        passwordGenerationOptions = options
        try setPasswordGenerationOptionsResult.get()
    }

    func setUsernameGenerationOptions(_ options: UsernameGenerationOptions) async throws {
        usernameGenerationOptions = options
        try setUsernameGenerationOptionsResult.get()
    }
}
