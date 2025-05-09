import BitwardenKit

public extension FeatureFlag {
    /// A test feature flag that isn't remotely configured and has no initial value.
    static let testLocalFeatureFlag = FeatureFlag(
        rawValue: "test-local-feature-flag",
        isRemotelyConfigured: false
    )

    /// A test feature flag that has an initial boolean value and is not remotely configured.
    static let testLocalInitialBoolFlag = FeatureFlag(
        rawValue: "test-local-initial-bool-flag",
        initialValue: .bool(true),
        isRemotelyConfigured: false
    )

    /// A test feature flag that has an initial integer value and is not remotely configured.
    static let testLocalInitialIntFlag = FeatureFlag(
        rawValue: "test-local-initial-int-flag",
        initialValue: .int(42),
        isRemotelyConfigured: false
    )

    /// A test feature flag that has an initial string value and is not remotely configured.
    static let testLocalInitialStringFlag = FeatureFlag(
        rawValue: "test-local-initial-string-flag",
        initialValue: .string("Test String"),
        isRemotelyConfigured: false
    )

    /// A test feature flag that can be remotely configured.
    static let testRemoteFeatureFlag = FeatureFlag(
        rawValue: "test-remote-feature-flag",
        isRemotelyConfigured: true
    )

    /// A test feature flag that has an initial boolean value and is not remotely configured.
    static let testRemoteInitialBoolFlag = FeatureFlag(
        rawValue: "test-remote-initial-bool-flag",
        initialValue: .bool(true),
        isRemotelyConfigured: true
    )

    /// A test feature flag that has an initial integer value and is not remotely configured.
    static let testRemoteInitialIntFlag = FeatureFlag(
        rawValue: "test-remote-initial-int-flag",
        initialValue: .int(42),
        isRemotelyConfigured: true
    )

    /// A test feature flag that has an initial string value and is not remotely configured.
    static let testRemoteInitialStringFlag = FeatureFlag(
        rawValue: "test-remote-initial-string-flag",
        initialValue: .string("Test String"),
        isRemotelyConfigured: true
    )
}
