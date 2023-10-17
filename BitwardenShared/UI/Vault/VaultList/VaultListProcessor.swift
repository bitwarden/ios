import Foundation

// MARK: - VaultListProcessor

/// The processor used to manage state and handle actions for the vault list screen.
///
final class VaultListProcessor: StateProcessor<VaultListState, VaultListAction, Void> {
    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<VaultRoute>

    // MARK: Initialization

    /// Creates a new `VaultListProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute>,
        state: VaultListState
    ) {
        self.coordinator = coordinator
        var state = state
        state.userInitials = "NA"
        super.init(state: state)
    }

    // MARK: Methods

    override func receive(_ action: VaultListAction) {
        switch action {
        case .addItemPressed:
            coordinator.navigate(to: .addItem)
        case .profilePressed:
            // TODO: BIT-124 Switch account
            break
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        }
    }
}
