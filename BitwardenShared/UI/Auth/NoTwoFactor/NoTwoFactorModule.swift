import Foundation

// MARK: - NoTwoFactorModule

/// An object that builds coordinators for the No Two Factor notice.
@MainActor
protocol NoTwoFactorModule {
    /// Initializes a coordinator for navigating between `NoTwoFactorRoute`s.
    ///
    /// - Parameters:
    ///   - delegate: A delegate of the `NoTwoFactorCoordinator`.
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `NoTwoFactorRoute`s.
    ///
    func makeNoTwoFactorNoticeCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<NoTwoFactorRoute, Void>
}

extension DefaultAppModule: NoTwoFactorModule {
    func makeNoTwoFactorNoticeCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<NoTwoFactorRoute, Void> {
        NoTwoFactorCoordinator(
            module: self,
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
