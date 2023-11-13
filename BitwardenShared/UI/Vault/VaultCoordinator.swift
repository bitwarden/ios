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
        case let .addItem(group):
            showAddItem(for: group.flatMap(CipherType.init))
        case let .alert(alert):
            stackNavigator.present(alert)
        case .dismiss:
            stackNavigator.dismiss()
        case .generator:
            showGenerator()
        case let .group(group):
            showGroup(group)
        case .list:
            showList()
        case .setupTotpCamera:
            showCamera()
        case let .viewItem(id):
            showViewItem(id: id)
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Shows the add item screen.
    ///
    /// - Parameter type: An optional `CipherType` to initialize this view with.
    ///
    private func showAddItem(for type: CipherType?) {
        let state = AddItemState(
            type: type ?? .login
        )
        let processor = AddItemProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: state
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

    /// Shows the vault group screen.
    ///
    private func showGroup(_ group: VaultListGroup) {
        let processor = VaultGroupProcessor(
            coordinator: asAnyCoordinator(),
            state: VaultGroupState(group: group)
        )
        let store = Store(processor: processor)
        let view = VaultGroupView(store: store)
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator.push(viewController)
    }

    /// Shows the vault list screen.
    ///
    private func showList() {
        if stackNavigator.isPresenting {
            stackNavigator.dismiss()
        } else {
            let processor = VaultListProcessor(
                coordinator: asAnyCoordinator(),
                services: services,
                state: VaultListState()
            )
            let store = Store(processor: processor)
            let view = VaultListView(store: store)
            stackNavigator.replace(view, animated: false)
        }
    }

    /// Shows the view item screen.
    ///
    /// - Parameter id: The id of the item to show.
    ///
    private func showViewItem(id: String) {
        let processor = ViewItemProcessor(
            coordinator: self,
            itemId: id,
            services: services,
            state: ViewItemState(
                typeState: .loading
            )
        )
        let store = Store(processor: processor)
        let view = ViewItemView(store: store)
        let stackNavigator = UINavigationController()
        stackNavigator.replace(view)
        self.stackNavigator.present(stackNavigator)
    }
}
