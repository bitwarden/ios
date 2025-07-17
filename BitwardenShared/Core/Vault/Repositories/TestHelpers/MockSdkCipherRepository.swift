import BitwardenKitMocks
import BitwardenSdk

@testable import BitwardenShared

final class MockSdkCipherRepository: BitwardenSdk.CipherRepository {
    var getResult: Result<BitwardenSdk.Cipher, Error> = .success(.fixture())
    var hasResult: Result<Bool, Error> = .success(true)
    var listResult: Result<[BitwardenSdk.Cipher], Error> = .success([])
    var removeResult: Result<Void, Error> = .success(())
    var removeReceivedId: String?
    var setReceivedId: String?
    var setReceivedCipher: Cipher?
    var setResult: Result<Void, Error> = .success(())

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
        removeReceivedId = id
        try removeResult.get()
    }

    func set(id: String, value: BitwardenSdk.Cipher) async throws {
        setReceivedId = id
        setReceivedCipher = value
        try setResult.get()
    }
}
