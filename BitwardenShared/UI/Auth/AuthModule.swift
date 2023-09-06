import UIKit

// MARK: - AuthModule

/// An object that builds coordinators for the auth flow.
@MainActor
public protocol AuthModule {
    /// Initializes a coordinator for navigating between `AuthRoute`s.
    ///
    /// - Parameter navigator: The object that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `AuthRoute`s.
    ///
    func makeAuthCoordinator(
        rootNavigator: RootNavigator?,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<AuthRoute>
}

// MARK: - DefaultAppModule

extension DefaultAppModule: AuthModule {
    public func makeAuthCoordinator(
        rootNavigator: RootNavigator?,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<AuthRoute> {
        AuthCoordinator(
            rootNavigator: rootNavigator,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
