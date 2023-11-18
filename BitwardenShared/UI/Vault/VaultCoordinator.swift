import SwiftUI

// MARK: - VaultCoordinatorDelegate

/// An object that is signaled when specific circumstances in the application flow have been encountered.
///
@MainActor
public protocol VaultCoordinatorDelegate: AnyObject {
    /// Called when the user taps add account.
    ///
    func didTapAddAccount()
}

// MARK: - VaultCoordinator

/// A coordinator that manages navigation in the vault tab.
///
final class VaultCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Module = GeneratorModule

    typealias Services = HasVaultRepository

        & GeneratorCoordinator.Services

    // MARK: Private Properties

    /// The delegate for this coordinator, used to notify when the user logs out.
    private weak var delegate: VaultCoordinatorDelegate?

    // MARK: - Private Properties

    /// The module used by this coordinator to create child coordinators.
    private let module: Module

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    var stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `VaultCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for this coordinator, relays user interactions with the profile switcher.
    ///   - module: The module used by this coordinator to create child coordinators.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        delegate: VaultCoordinatorDelegate,
        module: Module,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.module = module
        self.services = services
        self.stackNavigator = stackNavigator
        self.delegate = delegate
    }

    // MARK: Methods

    func navigate(to route: VaultRoute, context: AnyObject?) {
        switch route {
        case .addAccount:
            delegate?.didTapAddAccount()
        case let .addItem(group):
            showAddItem(for: group.flatMap(CipherType.init))
        case let .alert(alert):
            stackNavigator.present(alert)
        case .dismiss:
            stackNavigator.dismiss(all: false)
        case let .generator(type):
            guard let delegate = context as? GeneratorCoordinatorDelegate else { return }
            showGenerator(for: type, delegate: delegate)
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

    /// Shows the generator screen for the the specified type.
    ///
    /// - Parameters:
    ///   - type: The type to generate.
    ///   - delegate: The delegate for this generator flow.
    ///
    private func showGenerator(for type: GeneratorType, delegate: GeneratorCoordinatorDelegate) {
        let navigationController = UINavigationController()
        let coordinator = module.makeGeneratorCoordinator(
            delegate: delegate,
            stackNavigator: navigationController
        )
        coordinator.start()
        coordinator.navigate(to: .generator(staticType: type))
        stackNavigator.present(navigationController)
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
    ///
    /// - Parameter id: The id of the item to show.
    ///
    private func showViewItem(id: String) {
        let processor = ViewItemProcessor(
            coordinator: self,
            itemId: id,
            services: services,
            state: ViewItemState()
        )
        let store = Store(processor: processor)
        let view = ViewItemView(store: store)
        let stackNavigator = UINavigationController()
        stackNavigator.replace(view)
        self.stackNavigator.present(stackNavigator)
    }
}
