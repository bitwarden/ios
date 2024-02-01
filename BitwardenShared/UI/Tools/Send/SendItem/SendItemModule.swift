// MARK: - SendItemModule

/// An object that builds coordinators for the send item flow.
///
@MainActor
protocol SendItemModule {
    /// Initializes a coordinator for navigating between `SendItemRoute`s.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for the coordinator.
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `SendItemRoute`s.
    ///
    func makeSendItemCoordinator(
        delegate: SendItemDelegate,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<SendItemRoute, AuthAction>
}

extension DefaultAppModule: SendItemModule {
    func makeSendItemCoordinator(
        delegate: SendItemDelegate,
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<SendItemRoute, AuthAction> {
        SendItemCoordinator(
            delegate: delegate,
            module: self,
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
