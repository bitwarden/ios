import BitwardenKit
import BitwardenSdk
import Foundation

@testable import BitwardenShared

class MockKeychainRepository: KeychainRepository {
    var appId: String = "mockAppId"
    var mockStorage = [String: String]()
    var securityType: SecAccessControlCreateFlags?

    var deleteResult: Result<Void, Error> = .success(())
    var getResult: Result<String, Error>?
    var setResult: Result<Void, Error> = .success(())

    var deleteAllItemsCalled = false
    var deleteAllItemsResult: Result<Void, Error> = .success(())
    var deleteItemsForUserIds = [String]()
    var deleteItemsForUserResult: Result<Void, Error> = .success(())

    var getAccessTokenResult: Result<String, Error> = .success("ACCESS_TOKEN")
    var getAuthenticatorVaultKeyResult: Result<String, Error> = .success("AUTHENTICATOR_VAULT_KEY")
    var getDeviceKeyResult: Result<String, Error> = .success("DEVICE_KEY")
    var getPendingAdminLoginRequestResult: Result<String, Error> = .success("PENDING_REQUEST")
    var getRefreshTokenResult: Result<String, Error> = .success("REFRESH_TOKEN")
    var getServerCommunicationConfigResult: Result<BitwardenSdk.ServerCommunicationConfig?, Error> = .success(nil)
    var getServerCommunicationConfigCalledHostname: String? // swiftlint:disable:this identifier_name

    var setAuthenticatorVaultKeyResult: Result<Void, Error> = .success(())
    var setAccessTokenResult: Result<Void, Error> = .success(())
    var setDeviceKeyResult: Result<Void, Error> = .success(())
    var setPendingAdminLoginRequestResult: Result<Void, Error> = .success(())
    var setRefreshTokenResult: Result<Void, Error> = .success(())
    var setServerCommunicationConfigResult: Result<Void, Error> = .success(())
    var setServerCommunicationConfigCalledConfig: BitwardenSdk.ServerCommunicationConfig?
    var setServerCommunicationConfigCalledHostname: String? // swiftlint:disable:this identifier_name

    func deleteAllItems() async throws {
        deleteAllItemsCalled = true
        mockStorage.removeAll()
        try deleteAllItemsResult.get()
    }

    func deleteAuthenticatorVaultKey(userId: String) async throws {
        try deleteResult.get()
        let formattedKey = formattedKey(for: .authenticatorVaultKey(userId: userId))
        mockStorage = mockStorage.filter { $0.key != formattedKey }
    }

    func deleteItems(for userId: String) async throws {
        deleteItemsForUserIds.append(userId)
        mockStorage = mockStorage.filter { !$0.key.contains(userId) }
        try deleteItemsForUserResult.get()
    }

    func deleteDeviceKey(userId: String) async throws {
        let formattedKey = formattedKey(for: .deviceKey(userId: userId))
        mockStorage = mockStorage.filter { $0.key != formattedKey }
    }

    func deletePendingAdminLoginRequest(userId: String) async throws {
        try deleteResult.get()
        let formattedKey = formattedKey(for: .pendingAdminLoginRequest(userId: userId))
        mockStorage = mockStorage.filter { $0.key != formattedKey }
    }

    func deleteServerCommunicationConfig(hostname: String) async throws {
        try deleteResult.get()
        let formattedKey = formattedKey(for: .serverCommunicationConfig(hostname: hostname))
        mockStorage = mockStorage.filter { $0.key != formattedKey }
    }

    func deleteUserAuthKey(for item: BitwardenKeychainItem) async throws {
        try deleteResult.get()
        let formattedKey = formattedKey(for: item)
        mockStorage = mockStorage.filter { $0.key != formattedKey }
    }

    func getAccessToken(userId: String) async throws -> String {
        try getAccessTokenResult.get()
    }

    func getAuthenticatorVaultKey(userId: String) async throws -> String {
        try getValue(for: .authenticatorVaultKey(userId: userId))
    }

    func getDeviceKey(userId: String) async throws -> String? {
        try getValue(for: .deviceKey(userId: userId))
    }

    func getRefreshToken(userId: String) async throws -> String {
        try getRefreshTokenResult.get()
    }

    func getPendingAdminLoginRequest(userId: String) async throws -> String? {
        try getPendingAdminLoginRequestResult.get()
    }

    func getServerCommunicationConfig(hostname: String) async throws -> BitwardenSdk.ServerCommunicationConfig? {
        getServerCommunicationConfigCalledHostname = hostname
        return try getServerCommunicationConfigResult.get()
    }

    func getUserAuthKeyValue(for item: BitwardenKeychainItem) async throws -> String {
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

    func getValue(for item: BitwardenKeychainItem) throws -> String {
        let formattedKey = formattedKey(for: item)
        guard let value = mockStorage[formattedKey] else {
            throw KeychainServiceError.keyNotFound(item)
        }
        return value
    }

    func formattedKey(for item: BitwardenKeychainItem) -> String {
        String(format: storageKeyFormat, appId, item.unformattedKey)
    }

    func setAccessToken(_ value: String, userId: String) async throws {
        try setAccessTokenResult.get()
        mockStorage[formattedKey(for: .accessToken(userId: userId))] = value
    }

    func setAuthenticatorVaultKey(_ value: String, userId: String) async throws {
        try setAuthenticatorVaultKeyResult.get()
        mockStorage[formattedKey(for: .authenticatorVaultKey(userId: userId))] = value
    }

    func setDeviceKey(_ value: String, userId: String) async throws {
        mockStorage[formattedKey(for: .deviceKey(userId: userId))] = value
    }

    func setRefreshToken(_ value: String, userId: String) async throws {
        try setRefreshTokenResult.get()
        mockStorage[formattedKey(for: .refreshToken(userId: userId))] = value
    }

    func setPendingAdminLoginRequest(_ value: String, userId: String) async throws {
        try setPendingAdminLoginRequestResult.get()
        mockStorage[formattedKey(for: .pendingAdminLoginRequest(userId: userId))] = value
    }

    func setServerCommunicationConfig(
        _ config: BitwardenSdk.ServerCommunicationConfig?,
        hostname: String,
    ) async throws {
        setServerCommunicationConfigCalledConfig = config
        setServerCommunicationConfigCalledHostname = hostname
        try setServerCommunicationConfigResult.get()
    }

    func setUserAuthKey(for item: BitwardenKeychainItem, value: String) async throws {
        let formattedKey = formattedKey(for: item)
        securityType = item.accessControlFlags
        try setResult.get()
        mockStorage[formattedKey] = value
    }
}
