import Foundation

// MARK: - DebugMenuEffect

/// Effects that can be processed by a `DebugMenuProcessor`.
///
enum DebugMenuEffect: Equatable {
    /// Initiates the loading of feature flags from a remote source or local cache.
    case loadFeatureFlags

    /// Triggers a refresh of feature flags, clearing local settings and re-fetching from the remote source.
    case refreshFeatureFlags

    /// Toggles a specific feature flag's state.
    ///
    /// - Parameters:
    ///   - String: The identifier for the feature flag.
    ///   - Bool: The state to which the feature flag should be set (enabled or disabled).
    case toggleFeatureFlag(String, Bool)
}
