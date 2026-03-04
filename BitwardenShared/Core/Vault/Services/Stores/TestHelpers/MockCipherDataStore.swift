import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockCipherDataStore: CipherDataStore {
    var cipherCountUserId: String?
    var cipherCountResult: Result<Int, Error> = .success(0)

    var cipherChangesSubjectByUserId: [String: CurrentValueSubject<CipherChange, Never>] = [:]
    var cipherSubjectByUserId: [String: CurrentValueSubject<[Cipher], Error>] = [:]

    var deleteAllCiphersUserId: String?

    var deleteCipherId: String?
    var deleteCipherUserId: String?

    var fetchAllCiphersUserId: String?
    var fetchAllCiphersResult: Result<[Cipher], Error> = .success([])

    var fetchCipherId: String?
    var fetchCipherResult: Cipher?
    var fetchCipherUserId: String?

    var hasPersonalCiphersUserId: String?
    var hasPersonalCiphersResult: Result<Bool, Error> = .success(false)

    var replaceCiphersValue: [Cipher]?
    var replaceCiphersUserId: String?

    var upsertCipherValue: Cipher?
    var upsertCipherUserId: String?

    func cipherCount(userId: String) async throws -> Int {
        cipherCountUserId = userId
        return try cipherCountResult.get()
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

    func cipherChangesPublisher(userId: String) -> AnyPublisher<CipherChange, Never> {
        if let subject = cipherChangesSubjectByUserId[userId] {
            return subject.eraseToAnyPublisher()
        } else {
            let subject = CurrentValueSubject<CipherChange, Never>(.upserted(.fixture()))
            cipherChangesSubjectByUserId[userId] = subject
            return subject.dropFirst().eraseToAnyPublisher()
        }
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

    func hasPersonalCiphers(userId: String) async throws -> Bool {
        hasPersonalCiphersUserId = userId
        return try hasPersonalCiphersResult.get()
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
