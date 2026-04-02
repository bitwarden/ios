import AuthenticatorBridgeKit
import BitwardenKit
import CryptoKit
import Foundation

public extension MockSharedKeychainRepository {
    /// Generates a `Data` object that looks like the key used for encrypting shared items.
    /// Useful for tests that want reasonably authentic-looking data.
    func generateMockKeyData() -> Data {
        let key = SymmetricKey(size: .bits256)
        return key.withUnsafeBytes { Data(Array($0)) }
    }
}
