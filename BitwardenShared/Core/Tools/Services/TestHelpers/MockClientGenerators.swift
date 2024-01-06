import BitwardenSdk

class MockClientGenerators: ClientGeneratorsProtocol {
    var passphraseGeneratorRequest: PassphraseGeneratorRequest?
    var passphraseResult: Result<String, Error> = .success("PASSPHRASE")

    var passwordGeneratorRequest: PasswordGeneratorRequest?
    var passwordResult: Result<String, Error> = .success("PASSWORD")

    var usernameGeneratorRequest: UsernameGeneratorRequest?
    var usernameResult: Result<String, Error> = .success("USERNAME")

    func passphrase(settings: PassphraseGeneratorRequest) async throws -> String {
        passphraseGeneratorRequest = settings
        return try passphraseResult.get()
    }

    func password(settings: PasswordGeneratorRequest) async throws -> String {
        passwordGeneratorRequest = settings
        return try passwordResult.get()
    }

    func username(settings: UsernameGeneratorRequest) async throws -> String {
        usernameGeneratorRequest = settings
        return try usernameResult.get()
    }
}
