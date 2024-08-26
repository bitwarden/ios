import Foundation

// MARK: - FeatureFlag

/// An enum to represent a feature flag sent by the server
///
enum FeatureFlag: String, Codable {
    // MARK: Test Flags

    /// A test feature flag that has a local boolean default.
    case testLocalBoolFlag = "test-local-bool-flag"

    /// A test feature flag that has a local integer default.
    case testLocalIntFlag = "test-local-int-flag"

    /// A test feature flag that has a local string default.
    case testLocalStringFlag = "test-local-string-flag"

    /// A test feature flag to represent a value that doesn't have a local default.
    case testRemoteFlag

    // MARK: Static Properties

    /// The values to start the value for each flag at locally.
    /// If `isRemotelyConfigured` is true for the flag, then this will get overridden by the server;
    /// but if `isRemotelyConfigured` is false for the flag, then the value here will be used.
    /// This is a helpful way to manage local feature flags.
    static let initialLocalValues: [FeatureFlag: AnyCodable] = [
        .testLocalBoolFlag: .bool(true),
        .testLocalIntFlag: .int(42),
        .testLocalStringFlag: .string("Test String"),
    ]
}
