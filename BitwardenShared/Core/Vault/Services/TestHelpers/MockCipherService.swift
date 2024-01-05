import BitwardenSdk

@testable import BitwardenShared

class MockCipherService: CipherService {
    var replaceCiphersCiphers: [CipherDetailsResponseModel]?
    var replaceCiphersUserId: String?

    var shareWithServerCiphers = [Cipher]()
    var shareWithServerResult: Result<Void, Error> = .success(())

    func replaceCiphers(_ ciphers: [CipherDetailsResponseModel], userId: String) async throws {
        replaceCiphersCiphers = ciphers
        replaceCiphersUserId = userId
    }

    func shareWithServer(_ cipher: Cipher) async throws {
        shareWithServerCiphers.append(cipher)
        try shareWithServerResult.get()
    }
}
