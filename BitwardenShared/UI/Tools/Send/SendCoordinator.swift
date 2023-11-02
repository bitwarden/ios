// MARK: - SendCoordinator

/// A coordinator that manages navigation in the send tab.
///
final class SendCoordinator: Coordinator, HasStackNavigator {
    // MARK: - Private Properties

    /// The stack navigator that is managed by this coordinator.
    var stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `SendCoordinator`.
    ///
    /// - Parameters stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(stackNavigator: StackNavigator) {
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: SendRoute, context: AnyObject?) {
        switch route {
        case .addItem:
            showAddItem()
        case .list:
            showList()
        }
    }

    func start() {
        navigate(to: .list)
    }

    // MARK: Private methods

    /// Shows the add item screen.
    ///
    private func showAddItem() {
        stackNavigator.push(AddSendItemView())
    }

    /// Shows the list of sends.
    ///
    private func showList() {
        let processor = SendListProcessor(
            coordinator: asAnyCoordinator(),
            state: SendListState()
        )
        let store = Store(processor: processor)
        let view = SendListView(store: store)
        stackNavigator.replace(view)
    }
}
