import CryptoKit
import Foundation

public extension Data {
    // MARK: Initializers
    
    /// Parses bytes from a base64url-encoded string.
    init?(base64UrlEncoded str: String) throws {
        // .ignoreUnknownCharacters allows unpadded strings as a side-effect.
        try self.init(base64Encoded: str.urlDecoded(), options: .ignoreUnknownCharacters)
    }
    
    // MARK: Functions
    
    /// Encodes bytes in Data as a base64url string.
    func base64UrlEncodedString(trimPadding shouldTrim: Bool) -> String {
        let encoded = base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
        if shouldTrim {
            return encoded.trimmingCharacters(in: CharacterSet(["="]))
        } else {
            return encoded
        }
    }
    
    /// Generates a hash value for the provided data.
    ///
    /// - Parameter using: The type of cryptographically secure hashing being performed.
    ///
    /// - Returns: The data as a hash value.
    ///
    func generatedHash(
        using hashFunction: any HashFunction.Type,
    ) -> String {
        let digest = hashFunction.hash(data: self)
        let hashString = digest
            .compactMap { String(format: "%02x", $0) }
            .joined()
        return String(hashString)
    }

    /// Generates a hash value for the provided data using a non-standard base 64 encoded string.
    ///
    /// - Parameter using: The type of cryptographically secure hashing being performed.
    ///
    /// - Returns: The base 64 encoded string.
    ///
    @_optimize(none) // TODO: PM-25026 Remove when optimization for this is fixed on release config.
    func generatedHashBase64Encoded(
        using hashFunction: any HashFunction.Type,
    ) -> String {
        let digest = hashFunction.hash(data: self)
        return Data(digest).base64EncodedString()
    }

    /// Transforms this Data in a hex formatted string.
    /// - Returns: Hex formatted string.
    func asHexString() -> String {
        compactMap { String(format: "%02x", $0) }.joined()
    }
}
