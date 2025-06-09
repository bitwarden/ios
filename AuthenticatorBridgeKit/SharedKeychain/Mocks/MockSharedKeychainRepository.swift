import AuthenticatorBridgeKit
import BitwardenKit
import CryptoKit
import Foundation

public class MockSharedKeychainRepository: SharedKeychainRepository {
    public var authenticatorKey: Data?
    public var errorToThrow: Error?
    public var accountAutoLogoutTime = [String: Date]()

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

    public func getAccountAutoLogoutTime(userId: String) async throws -> Date? {
        if let errorToThrow { throw errorToThrow }

        return accountAutoLogoutTime[userId]
    }

    public func setAccountAutoLogoutTime(_ value: Date?, userId: String) async throws {
        if let errorToThrow { throw errorToThrow }

        accountAutoLogoutTime[userId] = value
    }
}
