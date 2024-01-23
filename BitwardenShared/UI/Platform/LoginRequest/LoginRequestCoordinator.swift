/// A coordinator that manages navigation for the login request view.
///
final class LoginRequestCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasAuthService
        & HasErrorReporter
        & HasStateService

    // MARK: Private Properties

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    var stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `LoginRequestCoordinator`.
    ///
    /// - Parameters:
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: LoginRequestRoute, context: AnyObject?) {
        switch route {
        case let .dismiss(onDismiss):
            stackNavigator.dismiss(animated: true, completion: {
                onDismiss?.action()
            })
        case let .loginRequest(loginRequest):
            showLoginRequest(loginRequest, delegate: context as? LoginRequestDelegate)
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Show the login request view.
    ///
    /// - Parameters:
    ///   - loginRequest: The login request to show.
    ///   - delegate: The delegate for the view.
    ///
    private func showLoginRequest(_ loginRequest: LoginRequest, delegate: LoginRequestDelegate?) {
        let processor = LoginRequestProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: LoginRequestState(request: loginRequest)
        )
        let view = LoginRequestView(store: Store(processor: processor))
        stackNavigator.replace(view)
    }
}
