import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockCipherDataStore: CipherDataStore {
    var cipherCountUserId: String?
    var cipherCountResult: Result<Int, Error> = .success(0)

    var deleteAllCiphersUserId: String?

    var deleteCipherId: String?
    var deleteCipherUserId: String?

    var fetchAllCiphersUserId: String?
    var fetchAllCiphersResult: Result<[Cipher], Error> = .success([])

    var fetchCipherId: String?
    var fetchCipherResult: Cipher?
    var fetchCipherUserId: String?

    var cipherSubjectByUserId: [String: CurrentValueSubject<[Cipher], Error>] = [:]

    var replaceCiphersValue: [Cipher]?
    var replaceCiphersUserId: String?

    var upsertCipherValue: Cipher?
    var upsertCipherUserId: String?

    func cipherCount(userId: String) async throws -> Int {
        cipherCountUserId = userId
        return try cipherCountResult.get()
    }

    func deleteAllCiphers(userId: String) async throws {
        deleteAllCiphersUserId = userId
    }

    func deleteCipher(id: String, userId: String) async throws {
        deleteCipherId = id
        deleteCipherUserId = userId
    }

    func fetchAllCiphers(userId: String) async throws -> [BitwardenSdk.Cipher] {
        fetchAllCiphersUserId = userId
        return try fetchAllCiphersResult.get()
    }

    func fetchCipher(withId id: String, userId: String) async -> Cipher? {
        fetchCipherId = id
        fetchCipherUserId = userId
        return fetchCipherResult
    }

    func cipherPublisher(userId: String) -> AnyPublisher<[Cipher], Error> {
        if let subject = cipherSubjectByUserId[userId] {
            return subject.eraseToAnyPublisher()
        } else {
            let subject = CurrentValueSubject<[Cipher], Error>([])
            cipherSubjectByUserId[userId] = subject
            return subject.eraseToAnyPublisher()
        }
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
