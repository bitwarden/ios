import BitwardenSdk

@testable import AuthenticatorShared

final class MockStateClient: StateClientProtocol {
    var registerCipherRepositoryReceivedStore: CipherRepository?
    var registerClientManagedRepositoriesReceivedRepositories: BitwardenSdk.Repositories? // swiftlint:disable:this identifier_name line_length
    var state: SqliteConfiguration?

    func initializeState(configuration: SqliteConfiguration) async throws {
        state = configuration
    }

    func registerCipherRepository(repository: CipherRepository) {
        registerCipherRepositoryReceivedStore = repository
    }

    func registerClientManagedRepositories(repositories: BitwardenSdk.Repositories) {
        registerClientManagedRepositoriesReceivedRepositories = repositories
    }
}
