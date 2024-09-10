import CryptoKit
import Foundation

@testable import AuthenticatorSyncShared

class MockSharedKeychainRepository {
    var authenticatorKey: Data?
}

extension MockSharedKeychainRepository: SharedKeychainRepository {
    func generateKeyData() -> Data {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data(Array($0)) }
    }

    func deleteAuthenticatorKey() throws {
        authenticatorKey = nil
    }

    func getAuthenticatorKey() async throws -> Data {
        if let authenticatorKey {
            return authenticatorKey
        } else {
            throw AuthenticatorKeychainServiceError.keyNotFound(.authenticatorKey)
        }
    }

    func setAuthenticatorKey(_ value: Data) async throws {
        authenticatorKey = value
    }
}
