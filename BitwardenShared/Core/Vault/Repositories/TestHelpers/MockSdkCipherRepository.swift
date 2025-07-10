import BitwardenKitMocks
import BitwardenSdk

@testable import BitwardenShared

final class MockSdkCipherRepository: BitwardenSdk.CipherRepository {
    var getResult: Result<BitwardenSdk.Cipher, Error> = .success(.fixture())
    var hasResult: Result<Bool, Error> = .success(true)
    var listResult: Result<[BitwardenSdk.Cipher], Error> = .success([])
    var removeError: Error?
    var removeReceivedId: String?
    var setError: Error?
    var setReceivedId: String?
    var setReceivedCipher: Cipher?

    func get(id: String) async throws -> BitwardenSdk.Cipher? {
        try getResult.get()
    }

    func has(id: String) async throws -> Bool {
        try hasResult.get()
    }

    func list() async throws -> [BitwardenSdk.Cipher] {
        try listResult.get()
    }

    func remove(id: String) async throws {
        if let removeError {
            throw removeError
        }
        removeReceivedId = id
    }

    func set(id: String, value: BitwardenSdk.Cipher) async throws {
        if let setError {
            throw setError
        }
        setReceivedId = id
        setReceivedCipher = value
    }
}
