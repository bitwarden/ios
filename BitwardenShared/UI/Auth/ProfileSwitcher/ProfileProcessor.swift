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
    }

    override func perform(_ effect: ProfileSwitcherEffect) async {
        await handler.handleProfileSwitcherEffect(effect)
//        switch effect {
//        case .refreshAccountProfiles:
//            await refreshProfileState()
//        default:
//            break
//        }
    }
}

//extension ProfileProcessor: ProfileSwitcherHandler {
//    var allowLockAndLogout: Bool {
////        handler.allowLockAndLogout
//        true
//    }
//
//    var profileServices: ProfileServices {
//        services
//    }
//
//    var profileSwitcherState: ProfileSwitcherState {
//        get {
//            super.state//.profileSwitcherState
//        }
//        set {
//            super.state = newValue
////            state.profileSwitcherState = newValue
////            state = newValue
//        }
//    }
//
//    var shouldHideAddAccount: Bool {
////        handler.shouldHideAddAccount
//        false
//    }
//
//    var toast: Toast? {
////        get {
////            handler.toast
////        }
////        set {
////            handler.toast = newValue
////        }
////        handler.toast
//        get {
////            state.toast
//            nil
//        }
//        set {
////            state.toast = newValue
//        }
//    }
//
//    func handleAuthEvent(_ authEvent: AuthEvent) async {
////        await handler.handleAuthEvent(authEvent)
//        guard case let .action(authAction) = authEvent else { return }
//        await coordinator.handleEvent(authAction)
//    }
//
//    func showAddAccount() {
////        handler.showAddAccount()
////        coordinator.navigate(to: .addAccount)
//    }
//
//    func showAlert(_ alert: Alert) {
////        handler.showAlert(alert)
//        coordinator.showAlert(alert)
//    }
//
//    func showProfileSwitcher() {
//        
//    }
//}
