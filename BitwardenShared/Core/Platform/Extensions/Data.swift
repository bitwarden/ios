import CryptoKit
import Foundation

extension Data {
    /// Generates a `SHA1` hash for the provided data.
    ///
    /// - Parameter using: The type of cryptographically secure hashing being performed.
    ///
    /// - Returns: The data as a `SHA1` hash.
    ///
    func generatedHash(
        using hashFunction: any HashFunction.Type
    ) -> String {
        let digest = hashFunction.hash(data: self)
        let hashString = digest
            .compactMap { String(format: "%02x", $0) }
            .joined()
        return String(hashString)
    }
}
