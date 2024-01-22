import Foundation

@testable import BitwardenShared

class MockKeychainService: KeychainService {
    var mockStorage = [String: String]()
    var securityType: SecAccessControlCreateFlags?
    var deleteResult: Result<Void, Error> = .success(())
    var getResult: Result<String, Error>?
    var setResult: Result<Void, Error> = .success(())

    func deleteUserAuthKey(for item: KeychainItem) async throws {
        try deleteResult.get()
        mockStorage = mockStorage.filter { $0.key != item.storageKey }
    }

    func getUserAuthKeyValue(for item: KeychainItem) async throws -> String {
        if let result = getResult {
            let value = try result.get()
            mockStorage[item.storageKey] = value
            return value
        } else if let value = mockStorage[item.storageKey] {
            return value
        } else {
            throw KeychainServiceError.keyNotFound(item)
        }
    }

    func setUserAuthKey(for item: KeychainItem, value: String) async throws {
        securityType = item.protection
        try setResult.get()
        mockStorage[item.storageKey] = value
    }
}
