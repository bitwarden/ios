import Foundation

@testable import BitwardenShared

class MockKeychainService: KeychainService {
    var appId: String = "mockAppId"
    var mockStorage = [String: String]()
    var securityType: SecAccessControlCreateFlags?
    var deleteResult: Result<Void, Error> = .success(())
    var getResult: Result<String, Error>?
    var setResult: Result<Void, Error> = .success(())

    func deleteUserAuthKey(for item: KeychainItem) async throws {
        try deleteResult.get()
        let formattedKey = formattedKey(for: item)
        mockStorage = mockStorage.filter { $0.key != formattedKey }
    }

    func getUserAuthKeyValue(for item: KeychainItem) async throws -> String {
        let formattedKey = formattedKey(for: item)
        if let result = getResult {
            let value = try result.get()
            mockStorage[formattedKey] = value
            return value
        } else if let value = mockStorage[formattedKey] {
            return value
        } else {
            throw KeychainServiceError.keyNotFound(item)
        }
    }

    func formattedKey(for item: KeychainItem) -> String {
        String(format: storageKeyFormat, appId, item.unformattedKey)
    }

    func setUserAuthKey(for item: KeychainItem, value: String) async throws {
        let formattedKey = formattedKey(for: item)
        securityType = item.protection
        try setResult.get()
        mockStorage[formattedKey] = value
    }
}
