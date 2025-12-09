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

    /// Flag to enable/disable forced KDF updates.
    static let forceUpdateKdfSettings = FeatureFlag(rawValue: "pm-18021-force-update-kdf-settings")

    /// Flag to enable/disable migration from My Vault Items to My Items.
    static let migrateMyVaultToMyItems = FeatureFlag(rawValue: "pm-20558-migrate-myvault-to-myitems")

    /// Flag to enable/disable not logging out when a user's KDF settings are changed.
    static let noLogoutOnKdfChange = FeatureFlag(rawValue: "pm-23995-no-logout-on-kdf-change")

    public static var allCases: [FeatureFlag] {
        [
            .cxpExportMobile,
            .cxpImportMobile,
            .cipherKeyEncryption,
            .enableCipherKeyEncryption,
            .forceUpdateKdfSettings,
            .migrateMyVaultToMyItems,
            .noLogoutOnKdfChange,
        ]
    }
}
