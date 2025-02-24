import Foundation

// MARK: - AuthRouter

/// An object for converting `AuthEvent` to an `AuthRoute`.
///
final class AuthRouter: NSObject, Router {
    // MARK: Types

    typealias Services = HasErrorReporter

    /// The services used by this router.
    let services: Services

    // MARK: Initialization

    /// Creates a new `AuthRouter`.
    ///
    /// - Parameter services: The services used by this router.
    ///
    /// - Parameters:
    init(services: Services) {
        self.services = services
    }

    /// Prepare the coordinator asynchronously for a redirected `AuthRoute` based on current state.
    ///
    /// - Parameter route: The proposed `AuthRoute`.
    /// - Returns: Either the supplied route or a new route if the coordinator state demands a different route.
    ///
    func handleAndRoute(_ event: AuthEvent) async -> AuthRoute {
        switch event {
        case .didCompleteAuth:
            .complete
        case .didStart:
            .vaultUnlock
        }
    }
}
