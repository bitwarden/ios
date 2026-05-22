import BitwardenKit
import Foundation

// MARK: - ServerConfig

/// Model that represents the configuration provided by the server at a particular time.
///
extension ServerConfig {
    // MARK: Methods

    /// Whether the server supports cipher key encryption.
    ///
    /// - Returns: `true` if it's supported, `false` otherwise.
    ///
    func supportsCipherKeyEncryption() -> Bool {
        guard let minVersion = ServerVersion(Constants.cipherKeyEncryptionMinServerVersion),
              let serverVersion = ServerVersion(version),
              minVersion <= serverVersion else {
            return false
        }
        return true
    }
}
