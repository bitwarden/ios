// MARK: - TutorialModule

/// An object that builds tutorial coordinators
///
@MainActor
protocol TutorialModule {
    /// Initializes a coordinator for navigating between `TutorialRoute` objects
    ///
    /// - Parameters:
    ///   - stackNavigator: The stack navigator
    /// - Returns: A coordinator
    ///
    func makeTutorialCoordinator(
        stackNavigator: StackNavigator
    ) -> AnyCoordinator<TutorialRoute, TutorialEvent>
}

extension DefaultAppModule: TutorialModule {
    func makeTutorialCoordinator(stackNavigator: StackNavigator) -> AnyCoordinator<TutorialRoute, TutorialEvent> {
        TutorialCoordinator(
            module: self,
            services: services,
            stackNavigator: stackNavigator
        ).asAnyCoordinator()
    }
}
