import Foundation

// MARK: - DebugMenuState

/// The state used to present the `DebugMenuView`.
///
struct DebugMenuState: Equatable, Sendable {
    /// The current feature flags supported.
    var featureFlags: [DebugMenuFeatureFlag] = []

    /// Computed property to get the isEnabled value for a given feature flag
    func isEnabled(for feature: FeatureFlag) -> Bool {
        featureFlags.first { $0.feature == feature }?.isEnabled ?? false
    }
}
