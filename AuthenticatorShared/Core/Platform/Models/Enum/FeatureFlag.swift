import BitwardenKit
import Foundation

// MARK: - FeatureFlag

/// An enum to represent a feature flag sent by the server
///
extension FeatureFlag: @retroactive CaseIterable {
    // MARK: Feature Flags

    /// A feature flag that determines whether or not the password manager sync capability is enabled.
    static let enablePasswordManagerSync = FeatureFlag(
        rawValue: "enable-pm-bwa-sync"
    )

    public static var allCases: [FeatureFlag] {
        [
            .enablePasswordManagerSync,
        ]
    }
}
