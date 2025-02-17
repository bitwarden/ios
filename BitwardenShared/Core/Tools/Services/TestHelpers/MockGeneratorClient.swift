import BitwardenSdk

class MockGeneratorClient: GeneratorClientsProtocol {
    var passphraseGeneratorRequest: PassphraseGeneratorRequest?
    var passphraseResult: Result<String, Error> = .success("PASSPHRASE")

    var passwordGeneratorRequest: PasswordGeneratorRequest?
    var passwordResult: Result<String, Error> = .success("PASSWORD")

    var usernameGeneratorRequest: UsernameGeneratorRequest?
    var usernameResult: Result<String, Error> = .success("USERNAME")

    func passphrase(settings: PassphraseGeneratorRequest) throws -> String {
        passphraseGeneratorRequest = settings
        return try passphraseResult.get()
    }

    func password(settings: PasswordGeneratorRequest) throws -> String {
        passwordGeneratorRequest = settings
        return try passwordResult.get()
    }

    func username(settings: UsernameGeneratorRequest) async throws -> String {
        usernameGeneratorRequest = settings
        return try usernameResult.get()
    }
}
