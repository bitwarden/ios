// MARK: - DebugMenuEffect

/// Effects that can be processed by a `DebugMenuProcessor`.
///
enum DebugMenuEffect: Equatable {
    /// Clears `userDecryptionOptions.masterPasswordUnlock` on the active account's
    /// cached profile to reproduce the pre-server-2025.11 state for PM-31723 testing.
    case clearMasterPasswordUnlock

    /// Clears the SSO server communication cookie value.
    case clearSsoCookies

    /// Triggers a refresh of feature flags, clearing local settings and re-fetching from the remote source.
    case refreshFeatureFlags

    /// Toggles a specific feature flag's state.
    ///
    /// - Parameters:
    ///   - String: The identifier for the feature flag.
    ///   - Bool: The state to which the feature flag should be set (enabled or disabled).
    case toggleFeatureFlag(String, Bool)

    /// The view appeared and is ready to load data.
    case viewAppeared
}
