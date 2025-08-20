import Foundation

// MARK: - TODO

class ProfileCoordinator: NSObject, Coordinator, HasStackNavigator {
    func navigate(to route: Void, context: AnyObject?) {
        let state = ProfileSwitcherState(accounts: [], activeAccountId: nil, allowLockAndLogout: true, isVisible: true)
        let processor = ProfileProcessor(state: state)
        let store = Store(processor: processor)
        let view = ProfileSwitcherSheet(store: store)
        stackNavigator?.replace(view)
    }
    
    typealias Event = Void

    typealias Route = Void

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
        stackNavigator: StackNavigator
    ) {
        self.stackNavigator = stackNavigator
    }
}
