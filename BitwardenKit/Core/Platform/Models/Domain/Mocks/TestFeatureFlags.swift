// swiftlint:disable:this file_name

import BitwardenKit

extension FeatureFlag: @retroactive CaseIterable {
    /// A test feature flag that has no initial value.
    public static let testFeatureFlag = FeatureFlag(
        rawValue: "test-feature-flag"
    )

    /// A test feature flag that has an initial boolean value.
    public static let testInitialBoolFlag = FeatureFlag(
        rawValue: "test-initial-bool-flag",
        initialValue: .bool(true)
    )

    /// A test feature flag that has an initial integer value.
    public static let testInitialIntFlag = FeatureFlag(
        rawValue: "test-initial-int-flag",
        initialValue: .int(42)
    )

    /// A test feature flag that has an initial string value.
    public static let testInitialStringFlag = FeatureFlag(
        rawValue: "test-initial-string-flag",
        initialValue: .string("Test String")
    )

    public static var allCases: [FeatureFlag] {
        [
            .testFeatureFlag,
            .testInitialBoolFlag,
            .testInitialIntFlag,
            .testInitialStringFlag,
        ]
    }
}
