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
    private(set) weak var stackNavigator: StackNavigator?

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
            stackNavigator?.dismiss()
        case let .passwordHistoryList(source):
            showPasswordHistoryListView(source)
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Show the password history view.
    ///
    /// - Parameter source: The source of the password history to display.
    ///
    private func showPasswordHistoryListView(_ source: PasswordHistoryListState.Source) {
        let processor = PasswordHistoryListProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: PasswordHistoryListState(source: source)
        )
        let view = PasswordHistoryListView(store: Store(processor: processor))
        stackNavigator?.replace(view)
    }
}
