final class ProfileProcessor: StateProcessor<
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

    // MARK: Initialization

    init(
        coordinator: AnyCoordinator<AuthRoute, AuthAction>,
        services: Services,
        state: ProfileSwitcherState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    override func receive(_ action: ProfileSwitcherAction) {
        handleProfileSwitcherAction(action)
    }

    override func perform(_ effect: ProfileSwitcherEffect) async {
        await handleProfileSwitcherEffect(effect)
//        switch effect {
//        case .refreshAccountProfiles:
//            await refreshProfileState()
//        default:
//            break
//        }
    }
}

extension ProfileProcessor: ProfileSwitcherHandler {
    var allowLockAndLogout: Bool {
        true
    }

    var profileServices: ProfileServices {
        services
    }

    var profileSwitcherState: ProfileSwitcherState {
        get {
            super.state//.profileSwitcherState
        }
        set {
            super.state = newValue
//            state.profileSwitcherState = newValue
//            state = newValue
        }
    }

    var shouldHideAddAccount: Bool {
        false
    }

    var toast: Toast? {
        get {
//            state.toast
            nil
        }
        set {
//            state.toast = newValue
        }
    }

    func handleAuthEvent(_ authEvent: AuthEvent) async {
        guard case let .action(authAction) = authEvent else { return }
        await coordinator.handleEvent(authAction)
    }

    func showAddAccount() {
//        coordinator.navigate(to: .addAccount)
    }

    func showAlert(_ alert: Alert) {
        coordinator.showAlert(alert)
    }
}
