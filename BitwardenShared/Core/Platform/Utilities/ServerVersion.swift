import Foundation
import OSLog

// MARK: - ServerVersion

/// Model that represents the server version.
///
struct ServerVersion: Comparable, Codable {
    // MARK: - Constants

    /// The separatator between version and legacy description.
    private static let suffixSeparator: Character = "-"

    /// The separatator between version's components.
    private static let versionSeparator: Character = "."

    // MARK: Parameters

    /// A string representing the version
    var version: String

    static func < (lhs: ServerVersion, rhs: ServerVersion) -> Bool {
        guard isValid(version: lhs.version), isValid(version: rhs.version) else {
            return false
        }

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
    
    static func == (lhs: ServerVersion, rhs: ServerVersion) -> Bool {
        guard isValid(version: lhs.version), isValid(version: rhs.version) else {
            return false // Or handle invalid cases differently
        }
        return lhs.version == rhs.version
    }
    
    // Manually override <= operator
    static func <= (lhs: ServerVersion, rhs: ServerVersion) -> Bool {
        return (lhs < rhs) || (lhs == rhs)
    }

    // Manually override >= operator
    static func >= (lhs: ServerVersion, rhs: ServerVersion) -> Bool {
        return (lhs > rhs) || (lhs == rhs)
    }

    private static func isValid(version: String) -> Bool {
        // Trim any leading or trailing whitespaces
        let trimmedVersion = version.trimmingCharacters(in: .whitespacesAndNewlines)

        // Regular expression pattern for a version string: X.Y.Z-metadata
        // where X, Y, Z are non-negative integers without leading zeros
        // and X cannot be only zeros
        // and an optional hyphen followed by alphanumeric metadata
        let regexPattern = "^[1-9][0-9]{3}\\.[0-9]+\\.[0-9]+(-[a-zA-Z0-9]+)*$"

        // Check if the trimmed version matches the regex pattern
        let regex = try? NSRegularExpression(pattern: regexPattern)
        let range = NSRange(location: 0, length: trimmedVersion.utf16.count)

        if let match = regex?.firstMatch(in: trimmedVersion, options: [], range: range) {
            return match.range.location != NSNotFound
        } else {
            Logger.application.error("Error with version format received: \(String(describing: version))")
            return false
        }
    }

    private func versionComponents() -> [Int] {
        let cleanServerVersion = version.split(separator: ServerVersion.suffixSeparator).first ?? ""
        return cleanServerVersion.split(separator: ServerVersion.versionSeparator).compactMap { Int($0) }
    }
}
