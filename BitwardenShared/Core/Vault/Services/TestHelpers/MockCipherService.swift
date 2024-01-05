import BitwardenSdk
@testable import BitwardenShared

class MockCipherService: CipherService {
    var replaceCiphersCiphers: [CipherDetailsResponseModel]?
    var replaceCiphersUserId: String?
    var deleteCipherId: String?
    var softDeleteCipherId: String?
    var softDeleteCipher: Cipher?

    func deleteCipherWithServer(id: String) async throws {
        deleteCipherId = id
    }

    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws {
        replaceCiphersCiphers = ciphers
        replaceCiphersUserId = userId
    }

    func softDeleteCipherWithServer(id: String, _ cipher: Cipher) async throws {
        softDeleteCipherId = id
        softDeleteCipher = cipher
    }
}
