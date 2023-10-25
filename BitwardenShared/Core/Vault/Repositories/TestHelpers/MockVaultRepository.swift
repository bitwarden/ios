import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockVaultRepository: VaultRepository {
    var addCipherCiphers = [BitwardenSdk.CipherView]()
    var addCipherResult: Result<Void, Error> = .success(())
    var cipherDetailsSubject = CurrentValueSubject<BitwardenSdk.CipherView, Never>(.fixture())
    var fetchSyncCalled = false
    var vaultListSubject = CurrentValueSubject<[VaultListSection], Never>([])
    var vaultListGroupSubject = CurrentValueSubject<[VaultListItem], Never>([])

    func fetchSync() async throws {
        fetchSyncCalled = true
    }

    func addCipher(_ cipher: BitwardenSdk.CipherView) async throws {
        addCipherCiphers.append(cipher)
        try addCipherResult.get()
    }

    func cipherDetailsPublisher(id: String) -> AsyncPublisher<AnyPublisher<BitwardenSdk.CipherView, Never>> {
        cipherDetailsSubject.eraseToAnyPublisher().values
    }

    func vaultListPublisher() -> AsyncPublisher<AnyPublisher<[BitwardenShared.VaultListSection], Never>> {
        vaultListSubject.eraseToAnyPublisher().values
    }

    func vaultListPublisher(
        group: BitwardenShared.VaultListGroup
    ) -> AsyncPublisher<AnyPublisher<[VaultListItem], Never>> {
        vaultListGroupSubject.eraseToAnyPublisher().values
    }
}
