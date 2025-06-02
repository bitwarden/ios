import CryptoKit
import Foundation

@testable import BitwardenKit

class MockSharedKeychainRepository {
    var authenticatorKey: Data?
    var errorToThrow: Error?
}

extension MockSharedKeychainRepository: SharedKeychainRepository {
//    func getLastActiveTime(application: BitwardenKit.SharedTimeoutApplication, userId: String) async throws -> Date? {
//        nil
//    }
//    
//    func setLastActiveTime(_ value: Date?, application: BitwardenKit.SharedTimeoutApplication, userId: String) async throws {
//
//    }
//    
//    func getVaultTimeout(application: BitwardenKit.SharedTimeoutApplication, userId: String) async throws -> BitwardenKit.SessionTimeoutValue? {
//        nil
//    }
//    
//    func setVaultTimeout(_ value: BitwardenKit.SessionTimeoutValue?, application: BitwardenKit.SharedTimeoutApplication, userId: String) async throws {
//
//    }
    
    func generateKeyData() -> Data {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data(Array($0)) }
    }

    func deleteAuthenticatorKey() throws {
        guard errorToThrow == nil else { throw errorToThrow! }

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
