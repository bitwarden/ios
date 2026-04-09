// MARK: - SelectLanguageModule

/// An object that builds coordinators for the Select Language flow.
///
@MainActor
public protocol SelectLanguageModule {
    /// Initializes a coordinator for navigating between `SelectLanguageRoute`s.
    ///
    /// - Parameters:
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `SelectLanguageRoute`s.
    ///
    func makeSelectLanguageCoordinator(
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<SelectLanguageRoute, Void>
}
