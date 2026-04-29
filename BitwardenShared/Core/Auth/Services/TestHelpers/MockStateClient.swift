import BitwardenSdk

@testable import BitwardenShared

final class MockStateClient: StateClientProtocol {
    var registerCipherRepositoryReceivedStore: CipherRepository?
    var registerClientManagedRepositoriesReceivedRepositories: BitwardenSdk.Repositories? // swiftlint:disable:this identifier_name line_length

    func registerCipherRepository(repository: CipherRepository) {
        registerCipherRepositoryReceivedStore = repository
    }

    func registerClientManagedRepositories(repositories: BitwardenSdk.Repositories) {
        registerClientManagedRepositoriesReceivedRepositories = repositories
    }
}
