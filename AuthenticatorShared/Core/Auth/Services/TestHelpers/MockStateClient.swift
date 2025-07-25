import BitwardenSdk

@testable import AuthenticatorShared

final class MockStateClient: StateClientProtocol {
    var registerCipherRepositoryReceivedStore: CipherRepository?

    func registerCipherRepository(store: CipherRepository) {
        registerCipherRepositoryReceivedStore = store
    }
}
