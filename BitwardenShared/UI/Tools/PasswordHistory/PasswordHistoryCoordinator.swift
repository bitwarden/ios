import BitwardenSdk

// MARK: - PasswordHistoryCoordinator

/// A coordinator that manages navigation for the password history view.
///
class PasswordHistoryCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasGeneratorRepository
        & HasPasteboardService

    // MARK: Properties

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    var stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `VaultCoordinator`.
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

    func navigate(to route: PasswordHistoryRoute, context _: AnyObject?) {
        switch route {
        case .dismiss:
            stackNavigator.dismiss()
        case let .passwordHistoryList(passwordHistory):
            showPasswordHistoryListView(passwordHistory)
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Show the password history view.
    ///
    /// - Parameter passwordHistory: The password history to display, if it's already known.
    ///
    private func showPasswordHistoryListView(_ passwordHistory: [PasswordHistoryView]?) {
        let state = PasswordHistoryListState(
            passwordHistory: passwordHistory ?? [],
            showClearButton: passwordHistory == nil
        )
        let processor = PasswordHistoryListProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: state
        )
        let view = PasswordHistoryListView(store: Store(processor: processor))
        stackNavigator.replace(view)
    }
}
