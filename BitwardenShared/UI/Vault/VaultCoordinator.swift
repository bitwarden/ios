import SwiftUI

// MARK: - VaultCoordinator

/// A coordinator that manages navigation in the vault tab.
///
final class VaultCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasVaultRepository

    // MARK: - Private Properties

    /// The services used by this coordinator.
    private let services: Services

    /// The stack navigator that is managed by this coordinator.
    var stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `VaultCoordinator`.
    ///
    /// - Parameters:
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(services: Services, stackNavigator: StackNavigator) {
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: VaultRoute, context: AnyObject?) {
        switch route {
        case .addItem:
            showAddItem()
        case let .alert(alert):
            stackNavigator.present(alert)
        case .generator:
            showGenerator()
        case .list:
            showList()
        case .setupTotpCamera:
            showCamera()
        case .viewItem:
            showViewItem()
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Shows the add item screen.
    ///
    private func showAddItem() {
        let processor = AddItemProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: AddItemState()
        )
        let store = Store(processor: processor)
        let view = AddItemView(store: store)
        let viewController = UIHostingController(rootView: view)
        let navigationController = UINavigationController(rootViewController: viewController)
        stackNavigator.present(navigationController)
    }

    /// Shows the totp camera setup screen.
    ///
    private func showCamera() {
        // TODO: BIT-874 Update to show the actual camera screen
        let view = Text("Camera")
        stackNavigator.present(view)
    }

    /// Shows the generator screen.
    ///
    private func showGenerator() {
        // TODO: BIT-875 Update to show the actual generator screen
        let view = Text("Generator")
        stackNavigator.present(view)
    }

    /// Shows the vault list screen.
    ///
    private func showList() {
        if stackNavigator.isPresenting {
            stackNavigator.dismiss()
        } else {
            let processor = VaultListProcessor(
                coordinator: asAnyCoordinator(),
                state: VaultListState()
            )
            let store = Store(processor: processor)
            let view = VaultListView(store: store)
            stackNavigator.replace(view, animated: false)
        }
    }

    /// Shows the view item screen.
    private func showViewItem() {
        // TODO: BIT-219 Present the actual view item screen
        let view = Text("View Item")
        stackNavigator.present(view)
    }
}
