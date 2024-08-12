import Foundation

// MARK: - FeatureFlag

/// An enum to represent a feature flag sent by the server
///
enum FeatureFlag: String, Codable {
    /// A feature flag for the intro carousel flow.
    case nativeCarouselFlow = "native-carousel-flow"

    /// A feature flag for showing the unassigned items banner.
    case unassignedItemsBanner = "unassigned-items-banner"
}
