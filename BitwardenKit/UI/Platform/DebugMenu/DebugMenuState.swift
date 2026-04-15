// MARK: - DebugMenuState

/// The state used to present the `DebugMenuView`.
///
struct DebugMenuState: Equatable, Sendable {
    /// The current feature flags supported.
    var featureFlags: [DebugMenuFeatureFlag] = []
    /// A toast message to show in the view.
    var toast: Toast?
    /// The active user's ID.
    var userID: String?
}
