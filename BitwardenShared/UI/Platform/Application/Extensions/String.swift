import Foundation

// MARK: - URLDecodingError

/// Errors that can be encountered when attempting to decode a string from it's url encoded format.
enum URLDecodingError: Error, Equatable {
    /// The provided string is an invalid length.
    ///
    /// Base64 encoded strings are padded at the end with `=` characters to ensure that the length of the resulting
    /// value is divisible by `4`. However, Base64 encoded strings _cannot_ have a remainder of `1` when divided by
    /// `4`.
    ///
    /// Example: `YMFhY` is considered invalid, and attempting to decode this value from a url or header value will
    /// throw this error.
    ///
    case invalidLength
}

// MARK: - String

extension String {
    // MARK: Properties

    /// A flag indicating if this string is considered a valid email address or not.
    ///
    /// An email is considered valid if it has at least one `@` symbol in it.
    var isValidEmail: Bool {
        contains("@")
    }

    // MARK: Methods

    /// Creates a new string that has been encoded for use in a url or request header.
    ///
    /// - Returns: A `String` encoded for use in a url or request header.
    ///
    func urlEncoded() -> String {
        replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    /// Creates a new string that has been decoded from a url or request header.
    ///
    /// - Throws: `URLDecodingError.invalidLength` if the length of this string is invalid.
    ///
    /// - Returns: A `String` decoded from use in a url or request header.
    ///
    func urlDecoded() throws -> String {
        let remainder = count % 4
        guard remainder != 1 else { throw URLDecodingError.invalidLength }

        return replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
            .appending(String(
                repeating: "=",
                count: remainder == 0 ? 0 : 4 - remainder
            ))
    }
}
