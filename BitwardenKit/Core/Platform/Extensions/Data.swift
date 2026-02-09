import CryptoKit
import Foundation

public extension Data {
    // MARK: Initializers

    /// Initializes a Data object from a base64url-encoded String.
    /// We have this as a convenience for working with WebAuthn data structures.
    ///
    /// - Parameters:
    ///   - base64urlEncoded: A base64url-encoded string.
    ///
    init?(base64urlEncoded str: String) throws {
        try self.init(base64Encoded: str.urlDecoded())
    }

    // MARK: Functions

    /// Provides the contents of this Data object as a base64url-encoded String.
    /// We have this as a convenience for working with WebAuthn data structures.
    ///
    /// NB: This will remove `=` padding characters at the end.
    ///
    /// - Returns: A base64url-encoded String representing this Data.
    ///
    func base64urlEncodedString() -> String {
        base64EncodedString()
            .urlEncoded()
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
