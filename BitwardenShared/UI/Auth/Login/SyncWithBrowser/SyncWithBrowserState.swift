import Foundation

// MARK: - SyncWithBrowserState

/// An object that defines the current state of a `SyncWithBrowserView`.
///
struct SyncWithBrowserState: Equatable, Sendable {
    // MARK: Properties

    /// The vault URL from the SSO cookie config, used to construct the browser redirect URL
    /// and displayed to the user.
    var vaultUrl: String
}
