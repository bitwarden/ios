import BitwardenKit

// MARK: - PasswordAutoFillModule

/// An object that builds coordinators for the password autofill flow.
///
@MainActor
protocol PasswordAutoFillModule {
    /// Initializes a coordinator for navigating between `PasswordAutofillRoute`s.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for the coordinator, used to notify when external navigation
    ///     needs to occur.
    ///   - stackNavigator: The stack navigator that will be used to navigate between routes.
    /// - Returns: A coordinator that can navigate to `PasswordAutofillRoute`s.
    ///
    func makePasswordAutoFillCoordinator(
        delegate: PasswordAutoFillCoordinatorDelegate?,
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<PasswordAutofillRoute, PasswordAutofillEvent>
}

extension DefaultAppModule: PasswordAutoFillModule {
    func makePasswordAutoFillCoordinator(
        delegate: PasswordAutoFillCoordinatorDelegate?,
        stackNavigator: StackNavigator,
    ) -> AnyCoordinator<PasswordAutofillRoute, PasswordAutofillEvent> {
        PasswordAutoFillCoordinator(
            delegate: delegate,
            services: services,
            stackNavigator: stackNavigator,
        )
        .asAnyCoordinator()
    }
}
