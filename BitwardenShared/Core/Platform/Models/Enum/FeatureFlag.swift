import BitwardenKit
import Foundation

// MARK: - FeatureFlag

/// An enum to represent a feature flag sent by the server
extension FeatureFlag: @retroactive CaseIterable {
    /// Flag to enable/disable Credential Exchange export flow.
    static let cxpExportMobile = FeatureFlag(rawValue: "cxp-export-mobile")

    /// Flag to enable/disable Credential Exchange import flow.
    static let cxpImportMobile = FeatureFlag(rawValue: "cxp-import-mobile")

    /// Flag to enable/disable individual cipher encryption configured remotely.
    static let cipherKeyEncryption = FeatureFlag(rawValue: "cipher-key-encryption")

    /// An SDK flag that enables individual cipher encryption.
    static let enableCipherKeyEncryption = FeatureFlag(rawValue: "enableCipherKeyEncryption")

    /// A feature flag to enable the removal of card item types.
    static let removeCardPolicy = FeatureFlag(
        rawValue: "pm-16442-remove-card-item-type-policy"
    )

    public static var allCases: [FeatureFlag] {
        [
            .cxpExportMobile,
            .cxpImportMobile,
            .cipherKeyEncryption,
            .enableCipherKeyEncryption,
            .removeCardPolicy,
        ]
    }
}
