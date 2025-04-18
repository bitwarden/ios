// MARK: - TwoFactorNoticeCoordinator

/// A coordinator that manages navigation in the no-two-factor notice.
///
final class TwoFactorNoticeCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Module = AuthModule

    typealias Services = HasApplication
        & HasAuthRepository
        & HasEnvironmentService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasStateService
        & HasTimeProvider

    // MARK: Private Properties

    /// The module used by this coordinator to create child coordinators.
    private let module: Module

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `TwoFactorNoticeCoordinator`.
    ///
    /// - Parameters:
    ///   - module: The module used by this coordinator to create child coordinators.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        module: Module,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.module = module
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: TwoFactorNoticeRoute, context: AnyObject?) {
        switch route {
        case .dismiss:
            stackNavigator?.dismiss()
        case let .emailAccess(allowDelay, emailAddress):
            showEmailAccess(allowDelay: allowDelay, emailAddress: emailAddress)
        case let .setUpTwoFactor(allowDelay, emailAddress):
            showSetUpTwoFactor(allowDelay: allowDelay, emailAddress: emailAddress)
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Shows the screen asking if the user can access their email.
    ///
    /// - Parameters:
    ///   - allowDelay: Whether or not the user can temporarily dismiss the notice.
    ///   - emailAddress: The email address of the user.
    func showEmailAccess(allowDelay: Bool, emailAddress: String) {
        let processor = EmailAccessProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: EmailAccessState(
                allowDelay: allowDelay,
                emailAddress: emailAddress
            )
        )
        let store = Store(processor: processor)
        let view = EmailAccessView(
            store: store
        )
        stackNavigator?.replace(view)
    }

    /// Shows the screen providing options for setting up two-factor authentication.
    ///
    /// - Parameters:
    ///   - allowDelay: Whether or not the user can temporarily dismiss the notice.
    ///   - emailAddress: The email address of the user.
    func showSetUpTwoFactor(allowDelay: Bool, emailAddress: String) {
        let processor = SetUpTwoFactorProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: SetUpTwoFactorState(
                allowDelay: allowDelay,
                emailAddress: emailAddress
            )
        )
        let store = Store(processor: processor)
        let view = SetUpTwoFactorView(
            store: store
        )
        stackNavigator?.push(view)
    }
}

// MARK: - HasErrorAlertServices

extension TwoFactorNoticeCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}
