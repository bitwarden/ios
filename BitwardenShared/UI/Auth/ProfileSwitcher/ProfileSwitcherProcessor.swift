// MARK: - ProfileSwitcherProcessor

/// The processor used to manage state and handle actions for the profile switcher sheet.
/// In practice, it just acts largely as a passthrough for the `ProfileSwitcherHandler` so as to
/// preserve flows in apps running on iOS pre-26.
final class ProfileSwitcherProcessor: StateProcessor<
    ProfileSwitcherState,
    ProfileSwitcherAction,
    ProfileSwitcherEffect
> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<AuthRoute, AuthAction>

    /// The services used by this processor.
    private let services: Services

    private let handler: ProfileSwitcherHandler

    // MARK: Initialization

    init(
        coordinator: AnyCoordinator<AuthRoute, AuthAction>,
        handler: ProfileSwitcherHandler,
        services: Services,
        state: ProfileSwitcherState
    ) {
        self.coordinator = coordinator
        self.handler = handler
        self.services = services
        super.init(state: state)
    }

    override func receive(_ action: ProfileSwitcherAction) {
        handler.handleProfileSwitcherAction(action)
        if case .dismissTapped = action {
            coordinator.navigate(to: .dismiss)
        }
    }

    override func perform(_ effect: ProfileSwitcherEffect) async {
        await handler.handleProfileSwitcherEffect(effect)
    }
}
