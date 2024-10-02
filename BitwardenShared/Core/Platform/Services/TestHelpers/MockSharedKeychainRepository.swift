import CryptoKit
import Foundation

@testable import AuthenticatorBridgeKit

class MockSharedKeychainRepository {
    var authenticatorKey: Data?
    var errorToThrow: Error?
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
        guard errorToThrow == nil else { throw errorToThrow! }

        if let authenticatorKey {
            return authenticatorKey
        } else {
            throw AuthenticatorKeychainServiceError.keyNotFound(.authenticatorKey)
        }
    }

    func setAuthenticatorKey(_ value: Data) async throws {
        guard errorToThrow == nil else { throw errorToThrow! }

        authenticatorKey = value
    }
}
