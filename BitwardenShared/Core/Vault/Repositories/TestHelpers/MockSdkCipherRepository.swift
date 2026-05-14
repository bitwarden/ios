import BitwardenKitMocks
import BitwardenSdk

@testable import BitwardenShared

final class MockSdkCipherRepository: BitwardenSdk.CipherRepository {
    var getResult: Result<BitwardenSdk.Cipher, Error> = .success(.fixture())
    var hasResult: Result<Bool, Error> = .success(true)
    var listResult: Result<[BitwardenSdk.Cipher], Error> = .success([])
    var removeAllResult: Result<Void, Error> = .success(())
    var removeBulkReceivedKeys: [String]?
    var removeBulkResult: Result<Void, Error> = .success(())
    var removeReceivedId: String?
    var removeResult: Result<Void, Error> = .success(())
    var setReceivedId: String?
    var setReceivedCipher: Cipher?
    var setResult: Result<Void, Error> = .success(())
    var setBulkReceivedValues: [String: BitwardenSdk.Cipher]?
    var setBulkResult: Result<Void, Error> = .success(())

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

    func removeAll() async throws {
        try removeAllResult.get()
    }

    func removeBulk(keys: [String]) async throws {
        removeBulkReceivedKeys = keys
        try removeBulkResult.get()
    }

    func set(id: String, value: BitwardenSdk.Cipher) async throws {
        setReceivedId = id
        setReceivedCipher = value
        try setResult.get()
    }

    func setBulk(values: [String: BitwardenSdk.Cipher]) async throws {
        setBulkReceivedValues = values
        try setBulkResult.get()
    }
}
