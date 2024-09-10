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

    /// A feature flag for the intro carousel flow.
    case nativeCarouselFlow = "native-carousel-flow"

    /// A feature flag for the create account flow.
    case nativeCreateAccountFlow = "native-create-account-flow"

    // MARK: Test Flags

    /// A test feature flag that isn't remotely configured.
    case testLocalFeatureFlag = "test-local-feature-flag"

    /// A test feature flag that can be remotely configured.
    case testRemoteFeatureFlag = "test-remote-feature-flag"

    // MARK: Properties

    /// Whether this feature can be enabled remotely.
    var isRemotelyConfigured: Bool {
        switch self {
        case .enableAuthenticatorSync,
             .nativeCarouselFlow,
             .nativeCreateAccountFlow,
             .testLocalFeatureFlag:
            false
        case .emailVerification,
             .testRemoteFeatureFlag:
            true
        }
    }
}
