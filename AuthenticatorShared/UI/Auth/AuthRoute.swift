import Foundation

// MARK: - AuthRoute

/// A route to a specific screen in the authentication flow.
public enum AuthRoute: Equatable {
    /// Dismisses the auth flow.
    case complete

    /// A route to the unlock screen.
    case vaultUnlock
}
