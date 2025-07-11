import BitwardenSdk

@testable import BitwardenShared

final class MockStateClient: StateClientProtocol {
    var registerCipherRepositoryReceivedStore: CipherRepository?

    func registerCipherRepository(store: CipherRepository) {
        registerCipherRepositoryReceivedStore = store
    }
}
