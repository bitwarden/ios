import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockVaultRepository: VaultRepository {
    var addCipherCiphers = [BitwardenSdk.CipherView]()
    var addCipherResult: Result<Void, Error> = .success(())
    var cipherDetailsSubject = CurrentValueSubject<BitwardenSdk.CipherView, Never>(.fixture())
    var deletedCipher = [String]()
    var deleteCipherResult: Result<Void, Error> = .success(())
    var fetchSyncCalled = false
    var getActiveAccountIdResult: Result<String, StateServiceError> = .failure(.noActiveAccount)
    var removeAccountIds = [String?]()
    var updateCipherCiphers = [BitwardenSdk.CipherView]()
    var updateCipherResult: Result<Void, Error> = .success(())
    var validatePasswordPasswords = [String]()
    var validatePasswordResult: Result<Bool, Error> = .success(true)
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

    func deleteCipher(_ id: String) async throws {
        deletedCipher.append(id)
        try deleteCipherResult.get()
    }

    func remove(userId: String?) async {
        removeAccountIds.append(userId)
    }

    func updateCipher(_ cipher: BitwardenSdk.CipherView) async throws {
        updateCipherCiphers.append(cipher)
        try updateCipherResult.get()
    }

    func validatePassword(_ password: String) async throws -> Bool {
        validatePasswordPasswords.append(password)
        return try validatePasswordResult.get()
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
