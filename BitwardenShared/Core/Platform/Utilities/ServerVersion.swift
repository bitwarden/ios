import Foundation
import OSLog

// MARK: - ServerVersion

/// Model that represents the server version.
///
struct ServerVersion: Comparable, Codable {
    // MARK: - Constants

    /// The separator between version and a suffix..
    private static let suffixSeparator: Character = "-"

    /// The separator between version's components.
    private static let versionSeparator: Character = "."

    // MARK: Parameters

    /// A string representing the version
    var version: String

    // MARK: Init

    /// Initializes a `SeverVersion` with the `version` if it's valid, otherwise returns `nil`.
    /// - Parameter version: The string`version` to use.
    init?(_ version: String) {
        let trimmedVersion = version.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValid(version: trimmedVersion) else {
            return nil
        }
        self.version = trimmedVersion
    }

    // MARK: Methods

    /// Compare if `lhs` is less than `rhs`
    /// - Parameters:
    ///   - lhs: Left hand side version to compare.
    ///   - rhs: Right hand side version to compare.
    /// - Returns: `true` if `lhs` is less than `rhs`, `false` otherwise.
    static func < (lhs: ServerVersion, rhs: ServerVersion) -> Bool {
        let lhsComponents = lhs.versionComponents()
        let rhsComponents = rhs.versionComponents()

        for (lhsComponent, rhsComponent) in zip(lhsComponents, rhsComponents) {
            if lhsComponent < rhsComponent {
                return true
            } else if lhsComponent > rhsComponent {
                return false
            }
        }
        return false
    }

    /// Compare if `lhs` is equal to `rhs`
    /// - Parameters:
    ///   - lhs: Left hand side version to compare.
    ///   - rhs: Right hand side version to compare.
    /// - Returns: `true` if `lhs` is equal to `rhs`, `false` otherwise.
    static func == (lhs: ServerVersion, rhs: ServerVersion) -> Bool {
        lhs.version == rhs.version
    }

    /// Checks whether the `version` has the correct format.
    /// - Parameter version: Version value to check.
    /// - Returns: `true` if valid, `false` otherwise.
    private static func isValid(version: String) -> Bool {
        // Regular expression pattern for a version string: X.Y.Z-metadata
        // where X, Y, Z are non-negative integers without leading zeros
        // and X cannot be only zeros
        // and an optional hyphen followed by alphanumeric metadata
        let regexPattern = "^[1-9][0-9]{3}\\.[0-9]+\\.[0-9]+(-[a-zA-Z0-9]+)*$"

        // Check if the trimmed version matches the regex pattern
        let regex = try? NSRegularExpression(pattern: regexPattern)
        let range = NSRange(location: 0, length: version.utf16.count)

        guard let match = regex?.firstMatch(in: version, options: [], range: range) else {
            Logger.application.error("Error with version format received: \(String(describing: version))")
            return false
        }

        return match.range.location != NSNotFound
    }

    /// Gets the version components in an array.
    /// - Returns: An array with each version component.
    private func versionComponents() -> [Int] {
        let cleanServerVersion = version.split(separator: ServerVersion.suffixSeparator).first ?? ""
        return cleanServerVersion.split(separator: ServerVersion.versionSeparator).compactMap { Int($0) }
    }
}
