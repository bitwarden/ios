import BitwardenSdk

@testable import BitwardenShared

class MockGeneratorRepository: GeneratorRepository {
    var passwordGeneratorRequest: PasswordGeneratorRequest?
    var passwordResult: Result<String, Error> = .success("PASSWORD")

    func generatePassword(settings: PasswordGeneratorRequest) async throws -> String {
        passwordGeneratorRequest = settings
        return try passwordResult.get()
    }
}
