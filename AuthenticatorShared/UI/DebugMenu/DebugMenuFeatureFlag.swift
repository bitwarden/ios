import Foundation

// MARK: - DebugMenuFeatureFlag

/// A structure representing a feature flag in the debug menu, including its enabled state.
/// This is used to display and manage feature flags within the debug menu interface.
///
struct DebugMenuFeatureFlag: Equatable, Identifiable {
    /// A unique identifier for the feature flag, based on its raw value.
    var id: String {
        feature.rawValue
    }

    /// The feature flag enum that this instance represents.
    let feature: FeatureFlag

    /// A boolean value indicating whether the feature is enabled or not.
    let isEnabled: Bool
}
