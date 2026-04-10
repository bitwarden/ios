import BitwardenKit

// MARK: - PremiumUpgradeModule

/// An object that builds coordinators for the premium upgrade view.
///
@MainActor
protocol PremiumUpgradeModule {
    /// Initializes a coordinator for navigating between `PremiumUpgradeRoute`s.
    ///
    /// - Parameter stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `PremiumUpgradeRoute`s.
    ///
    func makePremiumUpgradeCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<PremiumUpgradeRoute, Void>
}

extension DefaultAppModule: PremiumUpgradeModule {
    func makePremiumUpgradeCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<PremiumUpgradeRoute, Void> {
        PremiumUpgradeCoordinator(
            services: services,
            stackNavigator: stackNavigator,
        ).asAnyCoordinator()
    }
}
