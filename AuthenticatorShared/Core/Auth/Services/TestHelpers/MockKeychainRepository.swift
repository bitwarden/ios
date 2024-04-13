import Foundation

@testable import AuthenticatorShared

class MockKeychainRepository: KeychainRepository {
    var appId: String = "mockAppId"
    var mockStorage = [String: String]()
    var securityType: SecAccessControlCreateFlags?
    var deleteResult: Result<Void, Error> = .success(())
    var getResult: Result<String, Error>?
    var setResult: Result<Void, Error> = .success(())

    var getSecretKeyResult: Result<String, Error> = .success("qwerty")

    var setSecretKeyResult: Result<Void, Error> = .success(())

    var getAccessTokenResult: Result<String, Error> = .success("ACCESS_TOKEN")

    var getRefreshTokenResult: Result<String, Error> = .success("REFRESH_TOKEN")

    var setAccessTokenResult: Result<Void, Error> = .success(())

    var setRefreshTokenResult: Result<Void, Error> = .success(())

    func deleteUserAuthKey(for item: KeychainItem) async throws {
        try deleteResult.get()
        let formattedKey = formattedKey(for: item)
        mockStorage = mockStorage.filter { $0.key != formattedKey }
    }

    func getAccessToken(userId: String) async throws -> String {
        try getAccessTokenResult.get()
    }

    func getRefreshToken(userId: String) async throws -> String {
        try getRefreshTokenResult.get()
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

    func getValue(for item: KeychainItem) throws -> String {
        let formattedKey = formattedKey(for: item)
        guard let value = mockStorage[formattedKey] else {
            throw KeychainServiceError.keyNotFound(item)
        }
        return value
    }

    func formattedKey(for item: KeychainItem) -> String {
        String(format: storageKeyFormat, appId, item.unformattedKey)
    }

    func getSecretKey(userId: String) async throws -> String {
        try getSecretKeyResult.get()
    }

    func setSecretKey(_ value: String, userId: String) async throws {
        try setSecretKeyResult.get()
        mockStorage[formattedKey(for: .secretKey(userId: userId))] = value
    }
}
