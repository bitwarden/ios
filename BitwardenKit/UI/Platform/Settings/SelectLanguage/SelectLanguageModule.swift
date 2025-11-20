// MARK: - SelectLanguageModule

/// An object that builds coordinators for the Select Language flow.
///
@MainActor
public protocol SelectLanguageModule {
    /// Initializes a coordinator for navigating between `SelectLanguageRoute`s.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for updating the parent view after a language has been selected.
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `SelectLanguageRoute`s.
    ///
    func makeSelectLanguageCoordinator(
        delegate: SelectLanguageDelegate?,
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<SelectLanguageRoute, Void>
}
