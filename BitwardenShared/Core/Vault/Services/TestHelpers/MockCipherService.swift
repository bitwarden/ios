@testable import BitwardenShared

class MockCipherService: CipherService {
    var replaceCiphersCiphers: [CipherDetailsResponseModel]?
    var replaceCiphersUserId: String?
    var deleteCipherId: String?

    func deleteCipherWithServer(id: String) async throws {
        deleteCipherId = id
    }

    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws {
        replaceCiphersCiphers = ciphers
        replaceCiphersUserId = userId
    }
}
