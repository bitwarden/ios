import Foundation

// MARK: VaultGroupProcessor

/// A `Processor` that can handle `VaultGroupAction`s and `VaultGroupEffect`s.
final class VaultGroupProcessor: StateProcessor<VaultGroupState, VaultGroupAction, VaultGroupEffect> {
    // MARK: Private Properties

    /// The `Coordinator` for this processor.
    private var coordinator: any Coordinator<VaultRoute>

    // MARK: Initialization

    init(coordinator: any Coordinator<VaultRoute>, state: VaultGroupState) {
        self.coordinator = coordinator
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultGroupEffect) async {
        switch effect {
        case .appeared:
            // TODO: BIT-374 Attach to the stream of items in a vault repository
            break
        }
    }

    override func receive(_ action: VaultGroupAction) {
        switch action {
        case .addItemPressed:
            coordinator.navigate(to: .addItem(group: state.group))
        case let .itemPressed(item):
            coordinator.navigate(to: .viewItem)
        case let .morePressed(item):
            // TODO: BIT-375 Show the more menu
            print("more: \(item.id)")
            break
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        }
    }
}
