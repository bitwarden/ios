import Foundation

// MARK: - FeatureFlag

/// An enum to represent a feature flag sent by the server
///
enum FeatureFlag: String, Codable {
    /// Flag to enable/disable email verification during registration
    /// This flag introduces a new flow for account creation
    case emailVerification = "email-verification"

    /// A feature flag for the intro carousel flow.
    case nativeCarouselFlow = "native-carousel-flow"

    // MARK: Test Flags

    /// A test feature flag that isn't remotely configured.
    case testLocalFeatureFlag = "test-local-feature-flag"

    /// A test feature flag that can be remotely configured.
    case testRemoteFeatureFlag = "test-remote-feature-flag"

    // MARK: Properties

    /// Whether this feature can be enabled remotely.
    var isRemotelyConfigured: Bool {
        switch self {
        case .emailVerification,
             .nativeCarouselFlow,
             .testLocalFeatureFlag:
            false
        case .testRemoteFeatureFlag:
            true
        }
    }
}
