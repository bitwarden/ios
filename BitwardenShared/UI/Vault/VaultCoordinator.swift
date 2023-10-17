import SwiftUI

// MARK: - VaultCoordinator

/// A coordinator that manages navigation in the vault tab.
///
final class VaultCoordinator: Coordinator {
    // MARK: - Private Properties

    /// The stack navigator that is managed by this coordinator.
    private let stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `VaultCoordinator`.
    ///
    /// - Parameters stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(stackNavigator: StackNavigator) {
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func hideLoadingOverlay() {
        stackNavigator.hideLoadingOverlay()
    }

    func navigate(to route: VaultRoute, context: AnyObject?) {
        switch route {
        case .addItem:
            showAddItem()
        case .list:
            showList()
        }
    }

    func showLoadingOverlay(_ state: LoadingOverlayState) {
        stackNavigator.showLoadingOverlay(state)
    }

    func start() {}

    // MARK: Private Methods

    /// Shows the add item screen.
    ///
    private func showAddItem() {
        let view = Text("Add Item")
        stackNavigator.push(view)
    }

    /// Shows the vault list screen.
    ///
    private func showList() {
        let processor = VaultListProcessor(
            coordinator: asAnyCoordinator(),
            state: VaultListState()
        )
        let store = Store(processor: processor)
        let view = VaultListView(store: store)
        stackNavigator.push(view)
    }
}
