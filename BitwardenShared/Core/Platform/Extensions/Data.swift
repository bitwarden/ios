import CryptoKit
import Foundation

extension Data {
    /// Generates a hash value for the provided data.
    ///
    /// - Parameter using: The type of cryptographically secure hashing being performed.
    ///
    /// - Returns: The data as a hash value.
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
