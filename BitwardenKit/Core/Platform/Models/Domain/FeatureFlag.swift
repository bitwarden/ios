import Foundation

// MARK: - FeatureFlag

/// A struct that encapsulates information about a feature flag. Importing applications
/// should extend this struct to add static members representing each flag.
public struct FeatureFlag: Codable, Equatable, Sendable {
    /// The initial value of the feature flag.
    /// If `isRemotelyConfigured` is true for the flag, then this will get overridden by the server;
    /// but if `isRemotelyConfigured` is false for the flag, then the value here will be used.
    /// This is a helpful way to manage local feature flags.
    public let initialValue: AnyCodable?

    /// Whether this feature can be enabled remotely.
    public let isRemotelyConfigured: Bool

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
    ///   - isRemotelyConfigured: Whether this feature can be enabled remotely.
    public init(
        rawValue: String,
        initialValue: AnyCodable? = nil,
        isRemotelyConfigured: Bool = true
    ) {
        self.initialValue = initialValue
        self.isRemotelyConfigured = isRemotelyConfigured
        self.rawValue = rawValue
    }

}

// MARK: - FeatureFlag + Hashable

extension FeatureFlag: Hashable {
    public func hash(into hasher: inout Hasher) {
        rawValue.hash(into: &hasher)
    }
}
