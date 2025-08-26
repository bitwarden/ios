import Foundation

// MARK: - TODO

/// An object that is signaled when specific circumstances in the application flow have been encountered.
///
@MainActor
public protocol ProfileSwitcherCoordinatorDelegate: AnyObject {
    /// Called when the user locks their vault.
    ///
    /// - Parameters:
    ///   - userId: The user Id of the selected account. Defaults to the active user id if nil.
    ///   - isManuallyLocking: Whether the user is manually locking the account.
    ///
    func lockVault(userId: String?, isManuallyLocking: Bool)

    /// Called when the user has been logged out.
    ///
    /// - Parameters:
    ///   - userId: The id of the account to log out.
    ///   - userInitiated: Did a user action initiate this logout?
    ///
    func logout(userId: String?, userInitiated: Bool)

    /// Called when the user taps add account.
    ///
    func didTapAddAccount()

    /// Called when the user taps selects alternate account.
    ///
    ///  - Parameter userId: The userId of the selected account.
    ///
    func didTapAccount(userId: String)

    /// Present the login request view.
    ///
    /// - Parameter loginRequest: The login request.
    ///
    func presentLoginRequest(_ loginRequest: LoginRequest)

    /// When the user requests an account switch.
    ///
    /// - Parameters:
    ///   - userId: The user Id of the account.
    ///   - isAutomatic: Did the system trigger the account switch?
    ///   - authCompletionRoute: An optional route that should be navigated to after switching
    ///     accounts and vault unlock
    ///
    func switchAccount(userId: String, isAutomatic: Bool, authCompletionRoute: AppRoute?)

    /// Called when the user needs to switch to the settings tab and navigate to a `SettingsRoute`.
    ///
    /// - Parameter route: The route to navigate to in the settings tab.
    ///
    func switchToSettingsTab(route: SettingsRoute)

    /// The `State` for a toast view.
    var toast: Toast? { get set }
}

class ProfileCoordinator: NSObject, Coordinator, HasStackNavigator {
    func handleEvent(_ event: AuthAction, context: AnyObject?) async {
        switch event {
        case let .logout(userId, userInitiated):
            delegate?.logout(userId: userId, userInitiated: userInitiated)
        case let .lockVault(userId, isManuallyLocking):
            delegate?.lockVault(userId: userId, isManuallyLocking: isManuallyLocking)
        case let .switchAccount(isAutomatic, userId, authCompletionRoute):
            delegate?.switchAccount(
                userId: userId,
                isAutomatic: isAutomatic,
                authCompletionRoute: authCompletionRoute
            )
        }
    }
    
    // MARK: Types

    typealias Service = HasAuthRepository

    // MARK: Private Properties

    /// The delegate for this coordinator, used to notify when profile switching actions occur.
    private weak var delegate: ProfileSwitcherCoordinatorDelegate?

    private var handler: ProfileSwitcherHandler

    /// The services used by this coordinator.
    private let services: Services

    func navigate(to route: AuthRoute, context: AnyObject?) {
//        let state = services.authRepository.getProfilesState(allowLockAndLogout: true, isVisible: true, shouldAlwaysHideAddAccount: false, showPlaceholderToolbarIcon: true)
//        let state = ProfileSwitcherState(accounts: [], activeAccountId: nil, allowLockAndLogout: true, isVisible: true)
//        let state = ProfileSwitcherState.empty()
        let processor = ProfileProcessor(coordinator: asAnyCoordinator(),
                                         handler: handler,
                                         services: services,
                                         state: handler.profileSwitcherState)
        let store = Store(processor: processor)
        let view = ProfileSwitcherSheet(store: store)
        stackNavigator?.replace(view)
    }
    
    typealias Event = AuthAction

    typealias Route = AuthRoute

    func showErrorAlert(error: any Error, tryAgain: (() async -> Void)?, onDismissed: (() -> Void)?) async {

    }
    
    func start() {

    }
    
    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `ProfileSwitcherCoordinator`.
    /// TODO
    init(
//        delegate: ProfileSwitcherCoordinatorDelegate,
        handler: ProfileSwitcherHandler,
        services: Services,
        stackNavigator: StackNavigator
    ) {
//        self.delegate = delegate
        self.handler = handler
        self.services = services
        self.stackNavigator = stackNavigator
    }
}
