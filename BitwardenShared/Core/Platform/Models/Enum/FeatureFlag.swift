import BitwardenKit
import Foundation

// MARK: - FeatureFlag

/// An enum to represent a feature flag sent by the server
extension FeatureFlag: @retroactive CaseIterable {
    /// A feature flag to enable/disable account deprovisioning.
    static let accountDeprovisioning = FeatureFlag(rawValue: "pm-10308-account-deprovisioning")

    /// A feature flag to enable/disable the ability to add a custom domain for anonAddy users.
    static let anonAddySelfHostAlias = FeatureFlag(rawValue: "anon-addy-self-host-alias")

    /// A feature flag to enable/disable `AppIntent` execution.
    static let appIntents = FeatureFlag(rawValue: "app-intents")

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

    /// A feature flag for the flight recorder, which can be enabled to collect app logs.
    static let flightRecorder = FeatureFlag(
        rawValue: "enable-pm-flight-recorder",
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

    /// A feature flag for the create account flow.
    static let nativeCreateAccountFlow = FeatureFlag(rawValue: "native-create-account-flow")

    /// A feature flag for the pre-login settings.
    static let preLoginSettings = FeatureFlag(
        rawValue: "enable-pm-prelogin-settings",
        isRemotelyConfigured: false
    )

    /// A feature flag for the refactor on the SSO details endpoint.
    static let refactorSsoDetailsEndpoint = FeatureFlag(rawValue: "pm-12337-refactor-sso-details-endpoint")

    /// A feature flag for the use of new cipher permission properties.
    static let restrictCipherItemDeletion = FeatureFlag(
        rawValue: "pm-15493-restrict-item-deletion-to-can-manage-permission"
    )

    /// A feature flag to enable SimpleLogin self-host alias generation
    static let simpleLoginSelfHostAlias = FeatureFlag(rawValue: "simple-login-self-host-alias")

    public static var allCases: [FeatureFlag] {
        [
            .accountDeprovisioning,
            .anonAddySelfHostAlias,
            .appIntents,
            .cxpExportMobile,
            .cxpImportMobile,
            .cipherKeyEncryption,
            .emailVerification,
            .enableAuthenticatorSync,
            .enableCipherKeyEncryption,
            .flightRecorder,
            .ignore2FANoticeEnvironmentCheck,
            .importLoginsFlow,
            .mobileErrorReporting,
            .nativeCreateAccountFlow,
            .preLoginSettings,
            .refactorSsoDetailsEndpoint,
            .restrictCipherItemDeletion,
            .simpleLoginSelfHostAlias,
        ]
    }
}
