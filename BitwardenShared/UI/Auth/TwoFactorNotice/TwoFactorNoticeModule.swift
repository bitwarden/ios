import Foundation

// MARK: - TwoFactorNoticeModule

/// An object that builds coordinators for the No Two Factor notice.
@MainActor
protocol TwoFactorNoticeModule {
    /// Initializes a coordinator for navigating between `TwoFactorNoticeRoute`s.
    ///
    /// - Parameters:
    ///   - delegate: A delegate of the `TwoFactorNoticeCoordinator`.
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `TwoFactorNoticeRoute`s.
    ///
    func makeTwoFactorNoticeCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<TwoFactorNoticeRoute, Void>
}

extension DefaultAppModule: TwoFactorNoticeModule {
    func makeTwoFactorNoticeCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<TwoFactorNoticeRoute, Void> {
        TwoFactorNoticeCoordinator(
            module: self,
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
