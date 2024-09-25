import Foundation

// MARK: - FeatureFlag

/// An enum to represent a feature flag sent by the server
///
enum FeatureFlag: String, Codable {
    /// Flag to enable/disable email verification during registration
    /// This flag introduces a new flow for account creation
    case emailVerification = "email-verification"

    /// Flag to enable/disable the ability to sync TOTP codes with the Authenticator app.
    case enableAuthenticatorSync = "enable-authenticator-sync-ios"

    /// A flag that enables individual cipher encryption.
    case enableCipherKeyEncryption

    /// A feature flag for the intro carousel flow.
    case nativeCarouselFlow = "native-carousel-flow"

    /// A feature flag for the create account flow.
    case nativeCreateAccountFlow = "native-create-account-flow"

    // MARK: Test Flags

    /// A test feature flag that has an initial boolean value.
    case testInitialBoolFlag = "test-initial-bool-flag"

    /// A test feature flag that has an initial integer value.
    case testInitialIntFlag = "test-initial-int-flag"

    /// A test feature flag that has an initial string value.
    case testInitialStringFlag = "test-initial-string-flag"

    /// A test feature flag that isn't remotely configured.
    case testLocalFeatureFlag = "test-local-feature-flag"

    /// A test feature flag that can be remotely configured.
    case testRemoteFeatureFlag = "test-remote-feature-flag"

    // MARK: Type Properties

    /// An array of feature flags available in the debug menu.
    static var debugMenuFeatureFlags: [FeatureFlag] {
        [
            .emailVerification,
            .enableAuthenticatorSync,
            .nativeCarouselFlow,
            .nativeCreateAccountFlow,
        ]
    }

    /// The initial values for feature flags.
    /// If `isRemotelyConfigured` is true for the flag, then this will get overridden by the server;
    /// but if `isRemotelyConfigured` is false for the flag, then the value here will be used.
    /// This is a helpful way to manage local feature flags.
    static let initialValues: [FeatureFlag: AnyCodable] = [
        .testInitialBoolFlag: .bool(true),
        .testInitialIntFlag: .int(42),
        .testInitialStringFlag: .string("Test String"),
    ]

    // MARK: Instance Properties

    /// Whether this feature can be enabled remotely.
    var isRemotelyConfigured: Bool {
        switch self {
        case .enableAuthenticatorSync,
             .enableCipherKeyEncryption,
             .nativeCarouselFlow,
             .nativeCreateAccountFlow,
             .testLocalFeatureFlag:
            false
        case .emailVerification,
             .testInitialBoolFlag,
             .testInitialIntFlag,
             .testInitialStringFlag,
             .testRemoteFeatureFlag:
            true
        }
    }

    /// The display name of the feature flag.
    var name: String {
        switch self {
        case .emailVerification:
            "Email Verification"
        case .enableAuthenticatorSync:
            "Enable Authenticator Sync"
        case .enableCipherKeyEncryption:
            "Enable Cipher Key Encryption"
        case .nativeCarouselFlow:
            "Native Carousel Flow"
        case .nativeCreateAccountFlow:
            "Native Create Account Flow"
        case .testLocalFeatureFlag:
            "Test Local Feature Flag"
        case .testRemoteFeatureFlag:
            "Test Remote Feature Flag"
        case .testInitialBoolFlag:
            "Test Initial Boolean Flag"
        case .testInitialIntFlag:
            "Test Initial Integer Flag"
        case .testInitialStringFlag:
            "Test Initial String Flag"
        }
    }
}
