// MARK: - SendListProcessor

/// The processor used to manage state and handle actions for the send tab list screen.
///
final class SendListProcessor: StateProcessor<SendListState, SendListAction, SendListEffect> {
    // MARK: Types

    typealias Services = HasSendRepository

    // MARK: Private properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<SendRoute>

    /// The services required by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `SendListProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services required by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<SendRoute>,
        services: Services,
        state: SendListState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: SendListEffect) async {
        switch effect {
        case .appeared:
            for await sections in services.sendRepository.sendListPublisher() {
                state.sections = sections
            }
        }
    }

    override func receive(_ action: SendListAction) {
        switch action {
        case .addItemPressed:
            coordinator.navigate(to: .addItem)
        case .infoButtonPressed:
            break
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .sendListItemRow(rowAction):
            switch rowAction {
            case let .sendListItemPressed(item):

                print("tapped: \(item.id)")
            }
        }
    }
}
