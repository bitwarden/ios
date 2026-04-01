import BitwardenKit
import Foundation

// MARK: - FeatureFlag

/// An enum to represent a feature flag sent by the server
extension FeatureFlag: @retroactive CaseIterable {
    /// A feature flag to enable/disable ciphers archive option.
    static let archiveVaultItems = FeatureFlag(rawValue: "pm-19148-innovation-archive")

    /// Flag to enable/disable Credential Exchange export flow.
    static let cxpExportMobile = FeatureFlag(rawValue: "cxp-export-mobile")

    /// Flag to enable/disable individual cipher encryption configured remotely.
    static let cipherKeyEncryption = FeatureFlag(rawValue: "cipher-key-encryption")

    /// Flag to enable/disable Device Auth Key flows.
    static let deviceAuthKey = FeatureFlag(rawValue: "pm-27581-device-auth-key")

    /// An SDK flag that enables individual cipher encryption.
    static let enableCipherKeyEncryption = FeatureFlag(rawValue: "enableCipherKeyEncryption")

    /// Flag to enable/disable forced KDF updates.
    static let forceUpdateKdfSettings = FeatureFlag(rawValue: "pm-18021-force-update-kdf-settings")

    /// Flag to enable/disable migration from My Vault Items to My Items.
    static let migrateMyVaultToMyItems = FeatureFlag(rawValue: "pm-20558-migrate-myvault-to-myitems")

    /// Flag to enable/disable not logging out when a user's KDF settings are changed.
    static let noLogoutOnKdfChange = FeatureFlag(rawValue: "pm-23995-no-logout-on-kdf-change")

    /// Flag to enable/disable premium upgrade path.
    static let premiumUpgradePath = FeatureFlag(rawValue: "pm-31697-premium-upgrade-path")

    /// Flag to enable/disable sends email verification feature.
    static let sendEmailVerification = FeatureFlag(rawValue: "pm-19051-send-email-verification")

    public static var allCases: [FeatureFlag] {
        [
            .archiveVaultItems,
            .cxpExportMobile,
            .cipherKeyEncryption,
            .deviceAuthKey,
            .enableCipherKeyEncryption,
            .forceUpdateKdfSettings,
            .migrateMyVaultToMyItems,
            .noLogoutOnKdfChange,
            .premiumUpgradePath,
            .sendEmailVerification,
        ]
    }
}
