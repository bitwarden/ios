import Foundation

// MARK: - DebugMenuState

/// The state used to present the `DebugMenuView`.
///
struct DebugMenuState: Equatable, Sendable {
    /// The current feature flags supported.
    var featureFlags: [DebugMenuFeatureFlag] = []
}
