import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockCipherDataStore: CipherDataStore {
    var deleteAllCiphersUserId: String?

    var deleteCipherId: String?
    var deleteCipherUserId: String?

    var cipherSubject = CurrentValueSubject<[Cipher], Error>([])

    var replaceCiphersValue: [Cipher]?
    var replaceCiphersUserId: String?

    var upsertCipherValue: Cipher?
    var upsertCipherUserId: String?

    func deleteAllCiphers(userId: String) async throws {
        deleteAllCiphersUserId = userId
    }

    func deleteCipher(id: String, userId: String) async throws {
        deleteCipherId = id
        deleteCipherUserId = userId
    }

    func cipherPublisher(userId: String) -> AnyPublisher<[Cipher], Error> {
        cipherSubject.eraseToAnyPublisher()
    }

    func replaceCiphers(_ ciphers: [Cipher], userId: String) async throws {
        replaceCiphersValue = ciphers
        replaceCiphersUserId = userId
    }

    func upsertCipher(_ cipher: Cipher, userId: String) async throws {
        upsertCipherValue = cipher
        upsertCipherUserId = userId
    }
}
