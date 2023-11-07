// MARK: - SendListProcessor

/// The processor used to manage state and handle actions for the send tab list screen.
///
final class SendListProcessor: StateProcessor<SendListState, SendListAction, Void> {
    // MARK: Private properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SendRoute>

    // MARK: Initialization

    /// Creates a new `SendListProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SendRoute>,
        state: SendListState
    ) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: SendListAction) {
        switch action {
        case .addItemPressed:
            coordinator.navigate(to: .addItem)
        case .infoButtonPressed:
            break
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        }
    }
}
