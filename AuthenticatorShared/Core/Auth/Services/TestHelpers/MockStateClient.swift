import BitwardenSdk

@testable import AuthenticatorShared

final class MockStateClient: StateClientProtocol {
    var registerCipherRepositoryReceivedRepository: CipherRepository?
    var state: SqliteConfiguration?

    func initializeState(configuration: SqliteConfiguration) async throws {
        state = configuration
    }

    func registerCipherRepository(repository: CipherRepository) {
        registerCipherRepositoryReceivedRepository = repository
    }
}
