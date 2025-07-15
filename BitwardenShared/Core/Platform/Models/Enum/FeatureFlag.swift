import BitwardenKit
import Foundation

// MARK: - FeatureFlag

/// An enum to represent a feature flag sent by the server
extension FeatureFlag: @retroactive CaseIterable {
    /// A feature flag to enable/disable the ability to add a custom domain for anonAddy users.
    static let anonAddySelfHostAlias = FeatureFlag(rawValue: "anon-addy-self-host-alias")

    /// Flag to enable/disable Credential Exchange export flow.
    static let cxpExportMobile = FeatureFlag(rawValue: "cxp-export-mobile")

    /// Flag to enable/disable Credential Exchange import flow.
    static let cxpImportMobile = FeatureFlag(rawValue: "cxp-import-mobile")

    /// Flag to enable/disable individual cipher encryption configured remotely.
    static let cipherKeyEncryption = FeatureFlag(rawValue: "cipher-key-encryption")

    /// Flag to enable/disable email verification during registration
    /// This flag introduces a new flow for account creation
    static let emailVerification = FeatureFlag(rawValue: "email-verification")

    /// Flag to enable/disable the ability to sync TOTP codes with the Authenticator app.
    static let enableAuthenticatorSync = FeatureFlag(rawValue: "enable-pm-bwa-sync")

    /// An SDK flag that enables individual cipher encryption.
    static let enableCipherKeyEncryption = FeatureFlag(
        rawValue: "enableCipherKeyEncryption",
        isRemotelyConfigured: false
    )

    /// A flag to ignore the environment check for the two-factor authentication
    /// notice. If this is on, then it will display even on self-hosted servers,
    /// which means it's easier to dev/QA the feature.
    static let ignore2FANoticeEnvironmentCheck = FeatureFlag(
        rawValue: "ignore-2fa-notice-environment-check",
        isRemotelyConfigured: false
    )

    /// A feature flag for the import logins flow for new accounts.
    static let importLoginsFlow = FeatureFlag(rawValue: "import-logins-flow")

    /// A feature flag to enable additional error reporting.
    static let mobileErrorReporting = FeatureFlag(rawValue: "mobile-error-reporting")

    /// A feature flag for the use of new cipher permission properties.
    static let restrictCipherItemDeletion = FeatureFlag(
        rawValue: "pm-15493-restrict-item-deletion-to-can-manage-permission"
    )

    /// A feature flag to enable the removal of card item types.
    static let removeCardPolicy = FeatureFlag(
        rawValue: "pm-16442-remove-card-item-type-policy"
    )

    /// A feature flag to enable SimpleLogin self-host alias generation
    static let simpleLoginSelfHostAlias = FeatureFlag(rawValue: "simple-login-self-host-alias")

    public static var allCases: [FeatureFlag] {
        [
            .anonAddySelfHostAlias,
            .cxpExportMobile,
            .cxpImportMobile,
            .cipherKeyEncryption,
            .emailVerification,
            .enableAuthenticatorSync,
            .enableCipherKeyEncryption,
            .ignore2FANoticeEnvironmentCheck,
            .importLoginsFlow,
            .mobileErrorReporting,
            .removeCardPolicy,
            .restrictCipherItemDeletion,
            .simpleLoginSelfHostAlias,
        ]
    }
}
