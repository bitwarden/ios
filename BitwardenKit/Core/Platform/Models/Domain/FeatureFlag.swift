import Foundation

// MARK: - FeatureFlag

/// A struct that encapsulates information about a feature flag. Importing applications
/// should extend this struct to add static members representing each flag.
public struct FeatureFlag: Codable, Equatable, Sendable {
    /// The initial value of the feature flag. This will get overridden by the server, but this
    /// serves as a fallback and is a helpful way to manage local feature flags.
    public let initialValue: AnyCodable?

    /// The string name of the flag as sent by the server.
    public let rawValue: String

    /// The display name of the feature flag.
    public var name: String {
        rawValue.split(separator: "-").map(\.localizedCapitalized).joined(separator: " ")
    }

    /// Initializer for a feature flag.
    ///
    /// - Parameters:
    ///   - rawValue: The string name of the flag as sent by the server.
    ///   - initialValue: The initial value of the feature flag (if any).
    public init(
        rawValue: String,
        initialValue: AnyCodable? = nil
    ) {
        self.initialValue = initialValue
        self.rawValue = rawValue
    }
}

// MARK: - FeatureFlag + Hashable

extension FeatureFlag: Hashable {
    public func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}
