import BitwardenSdk
import Combine

@testable import BitwardenShared

class MockCipherService: CipherService {
    var ciphersSubject = CurrentValueSubject<[Cipher], Error>([])

    var fetchCipherId: String?
    var fetchCipherResult: Result<Cipher?, Error> = .success(nil)

    var replaceCiphersCiphers: [CipherDetailsResponseModel]?
    var replaceCiphersUserId: String?

    var cipherPublisherUserId: String?
    var cipherSubject = CurrentValueSubject<[Cipher], Error>([])

    var deleteCipherId: String?
    var deleteWithServerResult: Result<Void, Error> = .success(())

    var softDeleteCipherId: String?
    var softDeleteCipher: Cipher?
    var softDeleteWithServerResult: Result<Void, Error> = .success(())

    var shareWithServerCiphers = [Cipher]()
    var shareWithServerResult: Result<Void, Error> = .success(())

    var updateCipherCollectionsWithServerCiphers = [Cipher]()
    var updateCipherCollectionsWithServerResult: Result<Void, Error> = .success(())

    func cipherPublisher(userId: String) -> AnyPublisher<[BitwardenSdk.Cipher], Error> {
        cipherPublisherUserId = userId
        return cipherSubject.eraseToAnyPublisher()
    }

    func deleteCipherWithServer(id: String) async throws {
        deleteCipherId = id
        try deleteWithServerResult.get()
    }

    func fetchCipher(withId id: String) async throws -> Cipher? {
        fetchCipherId = id
        return try fetchCipherResult.get()
    }

    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws {
        replaceCiphersCiphers = ciphers
        replaceCiphersUserId = userId
    }

    func shareWithServer(_ cipher: Cipher) async throws {
        shareWithServerCiphers.append(cipher)
        try shareWithServerResult.get()
    }

    func softDeleteCipherWithServer(id: String, _ cipher: Cipher) async throws {
        softDeleteCipherId = id
        softDeleteCipher = cipher
        try softDeleteWithServerResult.get()
    }

    func updateCipherCollectionsWithServer(_ cipher: Cipher) async throws {
        updateCipherCollectionsWithServerCiphers.append(cipher)
        try updateCipherCollectionsWithServerResult.get()
    }

    func ciphersPublisher() async throws -> AnyPublisher<[BitwardenSdk.Cipher], Error> {
        ciphersSubject.eraseToAnyPublisher()
    }
}
