import CryptoKit
import Foundation
import SwiftUI

// MARK: - URLDecodingError

/// Errors that can be encountered when attempting to decode a string from it's url encoded format.
public enum URLDecodingError: Error, Equatable {
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

public extension String {
    // MARK: Type Properties

    /// En-dashes are used to represent number ranges. https://en.wikipedia.org/wiki/Dash#En_dash
    static let enDash = "\u{2013}"

    /// Double paragraph breaks to show the next line of text separated by a blank line.
    static let newLine = "\n\n"

    /// A word joiner. https://en.wikipedia.org/wiki/Word_joiner
    static let wordJoiner = "\u{2060}"

    /// A zero-width space. https://en.wikipedia.org/wiki/Zero-width_space
    static let zeroWidthSpace = "\u{200B}"

    // MARK: Properties

    /// Returns a color that's generated from the hash of the characters in the string. This can be
    /// used to create a consistent color based on the provided string.
    var hashColor: Color {
        let hash = unicodeScalars.reduce(into: 0) { result, scalar in
            result = Int(scalar.value) + ((result << 5) &- result)
        }

        let color = (0 ..< 3).reduce(into: "#") { result, index in
            let value = (hash >> (index * 8)) & 0xFF
            result += String(value, radix: 16).leftPadding(toLength: 2, withPad: "0")
        }

        return Color(hex: color)
    }

    /// Returns a SHA256-hashed version of this string as a hexadecimal string.
    var hexSHA256Hash: String {
        let hashedData = SHA256.hash(data: Data(utf8))
        return hashedData.map { String(format: "%02hhx", $0) }.joined()
    }

    /// A Boolean value indicating whether the string represents the "bitwarden" scheme for custom
    /// "bitwarden://" app URLs
    var isBitwardenAppScheme: Bool {
        self == "bitwarden"
    }

    /// A flag indicating if this string is considered a valid email address or not.
    ///
    /// An email is considered valid if it has at least one `@` symbol in it.
    var isValidEmail: Bool {
        contains("@")
    }

    /// Returns `true` if the URL is valid.
    var isValidURL: Bool {
        guard rangeOfCharacter(from: .whitespaces) == nil else { return false }

        let urlString: String = if starts(with: "https://") || starts(with: "http://") {
            self
        } else {
            "https://" + self
        }

        if #available(iOS 16, *) {
            return (try? URL(urlString, strategy: .url)) != nil
        } else {
            return URL(string: urlString) != nil
        }
    }

    /// Returns a new string that has been percent-encoded.
    /// This is aggressive compared to the W3C recommendations and percent-encodes
    /// all non-alphanumeric characters.
    var percentEncoded: String? {
        addingPercentEncoding(withAllowedCharacters: .alphanumerics)
    }

    // MARK: Methods

    /// Formats a credit card number by inserting spaces every 4 digits.
    /// Only formats if the string contains only digits, otherwise returns the original string.
    ///
    /// - Returns: A formatted credit card number with spaces every 4 digits,
    /// or the original string if not a valid card number.
    ///
    func formattedCreditCardNumber() -> String {
        // Only format if the string contains only digits and spaces
        let digitsOnly = replacingOccurrences(of: " ", with: "")
        guard digitsOnly.allSatisfy(\.isNumber) else {
            return self
        }

        // Insert spaces every 4 digits
        var result = ""
        for (index, character) in digitsOnly.enumerated() {
            if index > 0, index % 4 == 0 {
                result += " "
            }
            result += String(character)
        }

        return result
    }

    /// Returns a copy of the string, padded to the specified length on the left side with the
    /// provided padding character.
    ///
    /// - Parameters:
    ///   - toLength: The length of the string to return. If the string's length is less than this,
    ///     it will be padded with the provided character on the left/leading side.
    ///   - character: The character to use for padding.
    /// - Returns: A copy of the string, padded to the specified length on the left side.
    ///
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        if count < toLength {
            String(repeatElement(character, count: toLength - count)) + self
        } else {
            String(suffix(toLength))
        }
    }

    /// Returns a normalized URL string with an HTTPS scheme and no trailing slash.
    ///
    /// This method performs two normalization operations:
    /// 1. Removes any trailing slash from the URL
    /// 2. Prefixes the URL with `https://` if no scheme (`http://` or `https://`) is present
    ///
    /// If the URL already has an `http://` or `https://` scheme, it is preserved as-is
    /// (after removing any trailing slash).
    ///
    /// - Returns: A normalized URL string suitable for consistent URL matching and comparison.
    ///
    /// # Examples
    /// ```swift
    /// "example.com".httpsNormalized()        // "https://example.com"
    /// "example.com/".httpsNormalized()       // "https://example.com"
    /// "http://example.com".httpsNormalized() // "http://example.com"
    /// "https://example.com/".httpsNormalized() // "https://example.com"
    /// ```
    ///
    func httpsNormalized() -> String {
        let stringUrl = if hasSuffix("/") {
            String(dropLast())
        } else {
            self
        }

        guard stringUrl.starts(with: "https://") || stringUrl.starts(with: "http://") else {
            return "https://" + stringUrl
        }
        return stringUrl
    }

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
                count: remainder == 0 ? 0 : 4 - remainder,
            ))
    }

    /// Returns a copy of the string with all of the whitespace characters removed.
    ///
    /// - Returns: a copy of the string with all of the whitespace characters removed.
    ///
    func whitespaceRemoved() -> String {
        replacingOccurrences(of: "\\s", with: "", options: .regularExpression)
    }

    /// Creates a new string that prevents email addresses from being turned into tappable links
    /// when interpreted in a Markdown context. It does this by
    /// applying a Word Joiner character before the @, which is sufficient
    /// to break text autodetection. However, unlike using a zero-width
    /// space, this will not affect where very long lines would be broken.
    func withoutAutomaticEmailLinks() -> String {
        replacingOccurrences(of: "@", with: "\u{2060}@")
    }
}
