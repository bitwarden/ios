import BitwardenKit

// MARK: - BillingModule

/// An object that builds coordinators for billing views.
///
@MainActor
protocol BillingModule {
    /// Initializes a coordinator for navigating between `BillingRoute`s.
    ///
    /// - Parameter stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `BillingRoute`s.
    ///
    func makeBillingCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<BillingRoute, Void>
}

extension DefaultAppModule: BillingModule {
    func makeBillingCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<BillingRoute, Void> {
        BillingCoordinator(
            services: services,
            stackNavigator: stackNavigator,
        ).asAnyCoordinator()
    }
}
