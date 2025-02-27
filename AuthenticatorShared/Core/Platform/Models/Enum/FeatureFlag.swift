import Foundation

// MARK: - FeatureFlag

/// An enum to represent a feature flag sent by the server
///
enum FeatureFlag: String, CaseIterable, Codable {
    // MARK: Feature Flags

    /// A feature flag that determines whether or not the password manager sync capability is enabled.
    case enablePasswordManagerSync = "enable-pm-bwa-sync"

    // MARK: Test Flags

    /// A test feature flag that isn't remotely configured and has no initial value.
    case testLocalFeatureFlag = "test-local-feature-flag"

    /// A test feature flag that has an initial boolean value and is not remotely configured.
    case testLocalInitialBoolFlag = "test-local-initial-bool-flag"

    /// A test feature flag that has an initial integer value and is not remotely configured.
    case testLocalInitialIntFlag = "test-local-initial-int-flag"

    /// A test feature flag that has an initial string value and is not remotely configured.
    case testLocalInitialStringFlag = "test-local-initial-string-flag"

    /// A test feature flag that can be remotely configured.
    case testRemoteFeatureFlag = "test-remote-feature-flag"

    /// A test feature flag that has an initial boolean value and is not remotely configured.
    case testRemoteInitialBoolFlag = "test-remote-initial-bool-flag"

    /// A test feature flag that has an initial integer value and is not remotely configured.
    case testRemoteInitialIntFlag = "test-remote-initial-int-flag"

    /// A test feature flag that has an initial string value and is not remotely configured.
    case testRemoteInitialStringFlag = "test-remote-initial-string-flag"

    // MARK: Type Properties

    /// An array of feature flags available in the debug menu.
    static var debugMenuFeatureFlags: [FeatureFlag] {
        allCases.filter { !$0.rawValue.hasPrefix("test-") }
    }

    /// The initial values for feature flags.
    /// If `isRemotelyConfigured` is true for the flag, then this will get overridden by the server;
    /// but if `isRemotelyConfigured` is false for the flag, then the value here will be used.
    /// This is a helpful way to manage local feature flags.
    static let initialValues: [FeatureFlag: AnyCodable] = [
        .enablePasswordManagerSync: .bool(false),
        .testLocalInitialBoolFlag: .bool(true),
        .testLocalInitialIntFlag: .int(42),
        .testLocalInitialStringFlag: .string("Test String"),
        .testRemoteInitialBoolFlag: .bool(true),
        .testRemoteInitialIntFlag: .int(42),
        .testRemoteInitialStringFlag: .string("Test String"),
    ]

    // MARK: Instance Properties

    /// Whether this feature can be enabled remotely.
    var isRemotelyConfigured: Bool {
        switch self {
        case .testLocalFeatureFlag,
             .testLocalInitialBoolFlag,
             .testLocalInitialIntFlag,
             .testLocalInitialStringFlag:
            false
        case .enablePasswordManagerSync,
             .testRemoteFeatureFlag,
             .testRemoteInitialBoolFlag,
             .testRemoteInitialIntFlag,
             .testRemoteInitialStringFlag:
            true
        }
    }

    /// The display name of the feature flag.
    var name: String {
        rawValue.split(separator: "-").map(\.localizedCapitalized).joined(separator: " ")
    }
}
