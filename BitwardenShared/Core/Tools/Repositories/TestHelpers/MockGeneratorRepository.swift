import BitwardenSdk

@testable import BitwardenShared

class MockGeneratorRepository: GeneratorRepository {
    var passphraseGeneratorRequest: PassphraseGeneratorRequest?
    var passphraseResult: Result<String, Error> = .success("PASSPHRASE")

    var passwordGeneratorRequest: PasswordGeneratorRequest?
    var passwordResult: Result<String, Error> = .success("PASSWORD")

    var passwordGenerationOptions = PasswordGenerationOptions()

    var usernamePlusAddressEmail: String?
    var usernamePlusAddressEmailResult: Result<String, Error> = .success("user+abcd0123@bitwarden.com")

    func generatePassphrase(settings: PassphraseGeneratorRequest) async throws -> String {
        passphraseGeneratorRequest = settings
        return try passphraseResult.get()
    }

    func generatePassword(settings: PasswordGeneratorRequest) async throws -> String {
        passwordGeneratorRequest = settings
        return try passwordResult.get()
    }

    func generateUsernamePlusAddressedEmail(email: String) async throws -> String {
        usernamePlusAddressEmail = email
        return try usernamePlusAddressEmailResult.get()
    }

    func getPasswordGenerationOptions() async throws -> PasswordGenerationOptions {
        passwordGenerationOptions
    }

    func setPasswordGenerationOptions(_ options: PasswordGenerationOptions) async throws {
        passwordGenerationOptions = options
    }
}
