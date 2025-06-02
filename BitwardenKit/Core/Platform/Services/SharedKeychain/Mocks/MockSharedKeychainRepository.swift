import CryptoKit
import Foundation

@testable import BitwardenKit

public class MockSharedKeychainRepository: SharedKeychainRepository {
    var authenticatorKey: Data?
    var lastActiveTime = [String: Date]()
    var vaultTimeout = [String: SessionTimeoutValue]()

    func generateKeyData() -> Data {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data(Array($0)) }
    }

    public func deleteAuthenticatorKey() throws {
        authenticatorKey = nil
    }

    public func getAuthenticatorKey() async throws -> Data {
        if let authenticatorKey {
            return authenticatorKey
        } else {
            throw AuthenticatorKeychainServiceError.keyNotFound(.authenticatorKey)
        }
    }

    public func setAuthenticatorKey(_ value: Data) async throws {
        authenticatorKey = value
    }

    public func getLastActiveTime(application: SharedTimeoutApplication, userId: String) async throws -> Date? {
        lastActiveTime[SharedKeychainItem.lastActiveTime(application: application, userId: userId).unformattedKey]
    }

    public func setLastActiveTime(_ value: Date?, application: SharedTimeoutApplication, userId: String) async throws {
        lastActiveTime[SharedKeychainItem.lastActiveTime(application: application, userId: userId).unformattedKey] = value
    }

    public func getVaultTimeout(application: SharedTimeoutApplication, userId: String) async throws -> SessionTimeoutValue? {
        vaultTimeout[SharedKeychainItem.vaultTimeout(application: application, userId: userId).unformattedKey]
    }

    public func setVaultTimeout(_ value: SessionTimeoutValue?, application: SharedTimeoutApplication, userId: String) async throws {
        vaultTimeout[SharedKeychainItem.vaultTimeout(application: application, userId: userId).unformattedKey] = value
    }
}
