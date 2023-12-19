@testable import BitwardenShared

class MockCipherService: CipherService {
    var replaceCiphersCiphers: [CipherDetailsResponseModel]?
    var replaceCiphersUserId: String?

    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws {
        replaceCiphersCiphers = ciphers
        replaceCiphersUserId = userId
    }
}
