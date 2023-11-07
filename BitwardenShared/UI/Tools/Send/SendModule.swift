// MARK: - SendModule

/// An object that builds coordinators for the send tab.
///
@MainActor
protocol SendModule {
    /// Initializes a coordinator for navigating between `SendRoute`s.
    ///
    /// - Parameter stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `SendRoute`s.
    ///
    func makeSendCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<SendRoute>
}

extension DefaultAppModule: SendModule {
    func makeSendCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<SendRoute> {
        SendCoordinator(
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
