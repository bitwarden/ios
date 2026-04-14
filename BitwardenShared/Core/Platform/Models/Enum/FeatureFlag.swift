import BitwardenKit
import Foundation

// MARK: - FeatureFlag

/// An enum to represent a feature flag sent by the server
extension FeatureFlag: @retroactive CaseIterable {
    /// A feature flag to enable/disable V2 account encryption for JIT password registration.
    static let accountEncryptionV2JITPassword = FeatureFlag(
        rawValue: "enable-account-encryption-v2-jit-password-registration",
    )

    /// A feature flag to enable/disable V2 account encryption for Key Connector.
    static let accountEncryptionV2KeyConnector = FeatureFlag(
        rawValue: "enable-account-encryption-v2-key-connector-registration",
    )

    /// Flag to enable/disable V2 password-based registration using the SDK registration client.
    static let accountEncryptionV2PasswordRegistration = FeatureFlag(rawValue: "pm-27278-v2-password-registration")

    /// A feature flag to enable/disable V2 account encryption for TDE.
    static let accountEncryptionV2TDE = FeatureFlag(rawValue: "pm-27279-v2-registration-tde-jit")

    /// A feature flag to enable/disable scanning a card to autocomplete its details in add/edit cipher.
    static let cardScanner = FeatureFlag(rawValue: "pm-34171-card-scanner")

    /// Debug flag to disable self-hosted checks in premium upgrade flows for QA testing.
    static let debugDisableSelfHostPremiumCheck = FeatureFlag(
        rawValue: "debug-disable-self-host-premium-check",
    )

    /// Flag to enable/disable Device Auth Key flows.
    static let deviceAuthKey = FeatureFlag(rawValue: "pm-27581-device-auth-key")

    /// An SDK flag that enables individual cipher encryption.
    static let enableCipherKeyEncryption = FeatureFlag(rawValue: "enableCipherKeyEncryption")

    /// Flag to enable/disable Fill-Assist targeting rules.
    static let fillAssistTargetingRules = FeatureFlag(rawValue: "fill-assist-targeting-rules")

    /// Flag to enable/disable forced KDF updates.
    static let forceUpdateKdfSettings = FeatureFlag(rawValue: "pm-18021-force-update-kdf-settings")

    /// Flag to enable/disable migration from My Vault Items to My Items.
    static let migrateMyVaultToMyItems = FeatureFlag(rawValue: "pm-20558-migrate-myvault-to-myitems")

    /// Flag to enable/disable the new vault item types (Bank Account, Driver's License, Passport).
    static let newItemTypes = FeatureFlag(rawValue: "pm-32009-new-item-types")

    /// Flag to enable/disable not logging out when a user's KDF settings are changed.
    static let noLogoutOnKdfChange = FeatureFlag(rawValue: "pm-23995-no-logout-on-kdf-change")

    /// Flag to enable/disable the organization user notification banner policy.
    static let organizationUserNotificationBanner = FeatureFlag(rawValue: "pm-31948-org-user-notification-banner")

    /// Flag to enable/disable accepted-state organization policy enforcement via the SDK.
    ///
    /// When enabled, `PolicyService.policiesApplyingToUser` routes through the Bitwarden SDK
    /// so that policies are enforced against members in the accepted (not only confirmed) state.
    static let policiesInAcceptedState = FeatureFlag(rawValue: "pm-34145-policies-in-accepted-state")

    /// Flag to enable/disable premium upgrade path.
    static let premiumUpgradePath = FeatureFlag(rawValue: "pm-31697-premium-upgrade-path")

    public static var allCases: [FeatureFlag] {
        [
            .accountEncryptionV2JITPassword,
            .accountEncryptionV2KeyConnector,
            .accountEncryptionV2PasswordRegistration,
            .accountEncryptionV2TDE,
            .cardScanner,
            .debugDisableSelfHostPremiumCheck,
            .deviceAuthKey,
            .enableCipherKeyEncryption,
            .fillAssistTargetingRules,
            .forceUpdateKdfSettings,
            .migrateMyVaultToMyItems,
            .newItemTypes,
            .noLogoutOnKdfChange,
            .organizationUserNotificationBanner,
            .policiesInAcceptedState,
            .premiumUpgradePath,
        ]
    }
}
