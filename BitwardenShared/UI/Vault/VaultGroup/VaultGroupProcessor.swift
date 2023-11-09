import Foundation

// MARK: - VaultGroupProcessor

/// A `Processor` that can process `VaultGroupAction`s and `VaultGroupEffect`s.
final class VaultGroupProcessor: StateProcessor<VaultGroupState, VaultGroupAction, VaultGroupEffect> {
    // MARK: Private Properties

    /// The `Coordinator` for this processor.
    private var coordinator: any Coordinator<VaultRoute>

    // MARK: Initialization

    /// Creates a new `VaultGroupProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` for this processor.
    ///   - state: The initial state of this processor.
    ///
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
            switch item.itemType {
            case .cipher:
                coordinator.navigate(to: .viewItem(id: item.id))
            case let .group(group, _):
                coordinator.navigate(to: .group(group))
            }
        case let .morePressed(item):
            // TODO: BIT-375 Show the more menu
            print("more: \(item.id)")
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        }
    }
}
