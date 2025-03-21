import Foundation

// MARK: - FeatureFlag

/// An enum to represent a feature flag sent by the server
enum FeatureFlag: String, CaseIterable, Codable {
    /// A feature flag to enable/disable account deprovisioning.
    case accountDeprovisioning = "pm-10308-account-deprovisioning"

    /// A feature flag to enable/disable the app review prompt.
    case appReviewPrompt = "app-review-prompt"

    /// Flag to enable/disable Credential Exchange export flow.
    case cxpExportMobile = "cxp-export-mobile"

    /// Flag to enable/disable Credential Exchange import flow.
    case cxpImportMobile = "cxp-import-mobile"

    /// Flag to enable/disable individual cipher encryption configured remotely.
    case cipherKeyEncryption = "cipher-key-encryption"

    /// Flag to enable/disable email verification during registration
    /// This flag introduces a new flow for account creation
    case emailVerification = "email-verification"

    /// Flag to enable/disable the debug app review prompt.
    case enableDebugAppReviewPrompt = "enable-debug-app-review-prompt"

    /// Flag to enable/disable the ability to sync TOTP codes with the Authenticator app.
    case enableAuthenticatorSync = "enable-pm-bwa-sync"

    /// An SDK flag that enables individual cipher encryption.
    case enableCipherKeyEncryption

    /// A flag to ignore the environment check for the two-factor authentication
    /// notice. If this is on, then it will display even on self-hosted servers,
    /// which means it's easier to dev/QA the feature.
    case ignore2FANoticeEnvironmentCheck = "ignore-2fa-notice-environment-check"

    /// A feature flag for the import logins flow for new accounts.
    case importLoginsFlow = "import-logins-flow"

    /// A feature flag to enable/disable ciphers archive option.
    case innovationArchive = "pm-19148-innovation-archive"

    /// A feature flag for the intro carousel flow.
    case nativeCarouselFlow = "native-carousel-flow"

    /// A feature flag for the create account flow.
    case nativeCreateAccountFlow = "native-create-account-flow"

    /// A feature flag for the notice indicating a user does not have two-factor authentication set up.
    /// If true, the user can dismiss the notice temporarily.
    case newDeviceVerificationTemporaryDismiss = "new-device-temporary-dismiss"

    /// A feature flag for the notice indicating a user does not have two-factor authentication set up.
    /// If true, the user can not dismiss the notice, and must set up two-factor authentication.
    /// Overrides the temporary flag.
    case newDeviceVerificationPermanentDismiss = "new-device-permanent-dismiss"

    /// A feature flag for the refactor on the SSO details endpoint.
    case refactorSsoDetailsEndpoint = "pm-12337-refactor-sso-details-endpoint"

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
            .filter { $0 != .enableCipherKeyEncryption }
    }

    /// The initial values for feature flags.
    /// If `isRemotelyConfigured` is true for the flag, then this will get overridden by the server;
    /// but if `isRemotelyConfigured` is false for the flag, then the value here will be used.
    /// This is a helpful way to manage local feature flags.
    static let initialValues: [FeatureFlag: AnyCodable] = [
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
        case .enableCipherKeyEncryption,
             .enableDebugAppReviewPrompt,
             .ignore2FANoticeEnvironmentCheck,
             .newDeviceVerificationPermanentDismiss,
             .newDeviceVerificationTemporaryDismiss,
             .testLocalFeatureFlag,
             .testLocalInitialBoolFlag,
             .testLocalInitialIntFlag,
             .testLocalInitialStringFlag:
            false
        case .accountDeprovisioning,
             .appReviewPrompt,
             .cipherKeyEncryption,
             .cxpExportMobile,
             .cxpImportMobile,
             .emailVerification,
             .enableAuthenticatorSync,
             .importLoginsFlow,
             .innovationArchive,
             .nativeCarouselFlow,
             .nativeCreateAccountFlow,
             .refactorSsoDetailsEndpoint,
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
