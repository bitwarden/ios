import BitwardenSdk
import SwiftUI

// MARK: - VaultCoordinatorDelegate

/// An object that is signaled when specific circumstances in the application flow have been encountered.
///
@MainActor
public protocol VaultCoordinatorDelegate: AnyObject {
    /// Called when the user taps add account.
    ///
    func didTapAddAccount()

    /// Called when the user taps selects alternate account.
    ///
    ///  - Parameter userId: The userId of the selected account.
    ///
    func didTapAccount(userId: String)
}

// MARK: - VaultCoordinator

/// A coordinator that manages navigation in the vault tab.
///
final class VaultCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Module = GeneratorModule
        & VaultItemModule

    typealias Services = HasAuthRepository
        & HasCameraService
        & HasErrorReporter
        & HasVaultRepository
        & VaultItemCoordinator.Services

    // MARK: Private Properties

    /// The delegate for this coordinator, used to notify when the user logs out.
    private weak var delegate: VaultCoordinatorDelegate?

    // MARK: - Private Properties

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

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
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - delegate: The delegate for this coordinator, relays user interactions with the profile switcher.
    ///   - module: The module used by this coordinator to create child coordinators.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        appExtensionDelegate: AppExtensionDelegate?,
        delegate: VaultCoordinatorDelegate,
        module: Module,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.appExtensionDelegate = appExtensionDelegate
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
        case let .addItem(allowTypeSelection, group, uri):
            showVaultItem(route: .addItem(allowTypeSelection: allowTypeSelection, group: group, uri: uri))
        case let .alert(alert):
            stackNavigator.present(alert)
        case .autofillList:
            showAutofillList()
        case let .editItem(cipher: cipher):
            showVaultItem(route: .editItem(cipher: cipher))
        case .dismiss:
            stackNavigator.dismiss()
        case let .group(group):
            showGroup(group)
        case .list:
            showList()
        case let .viewItem(id):
            showVaultItem(route: .viewItem(id: id), delegate: context as? CipherItemOperationDelegate)
        case let .switchAccount(userId: userId):
            delegate?.didTapAccount(userId: userId)
        }
    }

    func start() {}

    // MARK: Private Methods

    /// Shows the autofill list screen.
    ///
    private func showAutofillList() {
        let processor = VaultAutofillListProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: asAnyCoordinator(),
            services: services,
            state: VaultAutofillListState()
        )
        let view = VaultAutofillListView(store: Store(processor: processor))
        stackNavigator.replace(view)
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

    /// Presents a vault item coordinator, which will navigate to the provided route.
    ///
    /// - Parameter route: The route to navigate to in the coordinator.
    ///
    private func showVaultItem(route: VaultItemRoute, delegate: CipherItemOperationDelegate? = nil) {
        let navigationController = UINavigationController()
        let coordinator = module.makeVaultItemCoordinator(stackNavigator: navigationController)
        coordinator.start()
        coordinator.navigate(to: route, context: delegate)

        stackNavigator.present(navigationController)
    }
}
