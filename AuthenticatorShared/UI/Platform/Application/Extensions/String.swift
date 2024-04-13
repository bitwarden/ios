import Foundation
import SwiftUI

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
    // MARK: Type Properties

    /// Double paragraph breaks to show the next line of text separated by a blank line.
    static let newLine = "\n\n"

    /// A zero width space. https://symbl.cc/en/200B/
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

    /// A flag indicating if this string is considered a valid email address or not.
    ///
    /// An email is considered valid if it has at least one `@` symbol in it.
    var isValidEmail: Bool {
        contains("@")
    }

    /// Returns `true` if the URL is valid.
    var isValidURL: Bool {
        guard rangeOfCharacter(from: .whitespaces) == nil else { return false }

        let urlString: String
        if starts(with: "https://") || starts(with: "http://") {
            urlString = self
        } else {
            urlString = "https://" + self
        }

        if #available(iOS 16, *) {
            return (try? URL(urlString, strategy: .url)) != nil
        } else {
            return URL(string: urlString) != nil
        }
    }

    // MARK: Methods

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
            return String(repeatElement(character, count: toLength - count)) + self
        } else {
            return String(suffix(toLength))
        }
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
                count: remainder == 0 ? 0 : 4 - remainder
            ))
    }
}
