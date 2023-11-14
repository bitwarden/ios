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
        case .generator:
            showGenerator()
        case let .group(group):
            showGroup(group)
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
            services: services,
            state: VaultGroupState(group: group)
        )
        let store = Store(processor: processor)
        let view = VaultGroupView(store: store)
        let viewController = UIHostingController(rootView: view)

        // Preset some navigation item values so that the navigation bar does not flash oddly once
        // the view's push animation has completed. This happens because `UIHostingController` does
        // not resolve its `navigationItem` properties until the view has been displayed on screen.
        // In this case, that doesn't happen until the push animation has completed, which results
        // in both the title and the search bar flashing into view after the push animation
        // completes. This occurs on all iOS versions (tested on iOS 17).
        //
        // The values set here are temporary, and are overwritten once the hosting controller has
        // resolved its root view's navigation bar modifiers.
        viewController.navigationItem.largeTitleDisplayMode = .never
        viewController.navigationItem.title = group.navigationTitle
        let searchController = UISearchController()
        if #available(iOS 16.0, *) {
            viewController.navigationItem.preferredSearchBarPlacement = .stacked
        }
        viewController.navigationItem.searchController = searchController
        viewController.navigationItem.hidesSearchBarWhenScrolling = false

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
    private func showViewItem() {
        // TODO: BIT-219 Present the actual view item screen
        let view = Text("View Item")
        stackNavigator.present(view)
    }
}
