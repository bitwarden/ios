import AuthenticatorBridgeKit
import BitwardenKit
import CryptoKit
import Foundation

public class MockSharedKeychainRepository: SharedKeychainRepository {
    public var authenticatorKey: Data?
    public var errorToThrow: Error?
    public var lastActiveTime = [String: Date]()
    public var vaultTimeout = [String: SessionTimeoutValue]()

    public init() {}

    public func generateKeyData() -> Data {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data(Array($0)) }
    }

    public func deleteAuthenticatorKey() throws {
        if let errorToThrow { throw errorToThrow }

        authenticatorKey = nil
    }

    public func getAuthenticatorKey() async throws -> Data {
        if let errorToThrow { throw errorToThrow }

        if let authenticatorKey {
            return authenticatorKey
        } else {
            throw SharedKeychainServiceError.keyNotFound(.authenticatorKey)
        }
    }

    public func setAuthenticatorKey(_ value: Data) async throws {
        if let errorToThrow { throw errorToThrow }

        authenticatorKey = value
    }

    public func getLastActiveTime(
        application: SharedTimeoutApplication,
        userId: String
    ) async throws -> Date? {
        lastActiveTime[SharedKeychainItem.lastActiveTime(application: application, userId: userId).unformattedKey]
    }

    public func setLastActiveTime(
        _ value: Date?,
        application: SharedTimeoutApplication,
        userId: String
    ) async throws {
        let entry = SharedKeychainItem.lastActiveTime(application: application, userId: userId)
        lastActiveTime[entry.unformattedKey] = value
    }

    public func getVaultTimeout(
        application: SharedTimeoutApplication,
        userId: String
    ) async throws -> SessionTimeoutValue? {
        let entry = SharedKeychainItem.vaultTimeout(application: application, userId: userId)
        return vaultTimeout[entry.unformattedKey]
    }

    public func setVaultTimeout(
        _ value: SessionTimeoutValue?,
        application: SharedTimeoutApplication,
        userId: String
    ) async throws {
        let entry = SharedKeychainItem.vaultTimeout(application: application, userId: userId)
        vaultTimeout[entry.unformattedKey] = value
    }
}
