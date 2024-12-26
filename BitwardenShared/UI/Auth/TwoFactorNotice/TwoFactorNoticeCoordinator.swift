// MARK: - TwoFactorNoticeCoordinator

/// A coordinator that manages navigation in the no-two-factor notice.
///
final class TwoFactorNoticeCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Module = AuthModule

    typealias Services = HasApplication
        & HasAuthRepository
        & HasEnvironmentService
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
        case let .emailAccess(allowDelay):
            showEmailAccess(allowDelay)
        case let .setUpTwoFactor(allowDelay):
            showSetUpTwoFactor(allowDelay)
        }
    }

    func start() {}

    // MARK: Private Methods

    func showEmailAccess(_ allowDelay: Bool) {
        let processor = EmailAccessProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: EmailAccessState(
                allowDelay: allowDelay
            )
        )
        let store = Store(processor: processor)
        let view = EmailAccessView(
            store: store
        )
        stackNavigator?.replace(view)
    }

    func showSetUpTwoFactor(_ allowDelay: Bool) {
        let processor = SetUpTwoFactorProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: SetUpTwoFactorState(
                allowDelay: allowDelay
            )
        )
        let store = Store(processor: processor)
        let view = SetUpTwoFactorView(
            store: store
        )
        stackNavigator?.push(view)
    }
}
