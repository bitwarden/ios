import Foundation

// MARK: - FeatureFlag

/// An enum to represent a feature flag sent by the server
///
enum FeatureFlag: String, Codable {
    case unassignedItemsBanner = "unassigned-items-banner"
}
