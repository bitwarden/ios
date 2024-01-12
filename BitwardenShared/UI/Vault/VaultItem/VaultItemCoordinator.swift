import BitwardenSdk
import SwiftUI

// MARK: - VaultItemCoordinator

/// A coordinator that manages navigation for displaying, editing, and adding individual vault items.
///
class VaultItemCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Module = GeneratorModule
        & VaultItemModule

    typealias Services = AuthenticatorKeyCaptureCoordinator.Services
        & GeneratorCoordinator.Services
        & HasTOTPService
        & HasVaultRepository

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
    ///   - module: The module used by this coordinator to create child coordinators.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        module: Module,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.module = module
        self.services = services
        self.stackNavigator = stackNavigator
    }

    func navigate(to route: VaultItemRoute, context: AnyObject?) {
        switch route {
        case let .addItem(allowTypeSelection, group, hasPremium, uri):
            showAddItem(
                for: group.flatMap(CipherType.init),
                allowTypeSelection: allowTypeSelection,
                hasPremium: hasPremium,
                uri: uri,
                delegate: context as? CipherItemOperationDelegate
            )
        case let .alert(alert):
            stackNavigator.present(alert)
        case let .cloneItem(cipher):
            showCloneItem(for: cipher, delegate: context as? CipherItemOperationDelegate)
        case let .dismiss(onDismiss):
            stackNavigator.dismiss(animated: true, completion: {
                onDismiss?.action()
            })
        case let .editCollections(cipher):
            showEditCollections(cipher: cipher, delegate: context as? EditCollectionsProcessorDelegate)
        case let .editItem(cipher, hasPremium):
            showEditItem(for: cipher, hasPremium: hasPremium, delegate: context as? CipherItemOperationDelegate)
        case let .generator(type, emailWebsite):
            guard let delegate = context as? GeneratorCoordinatorDelegate else { return }
            showGenerator(for: type, emailWebsite: emailWebsite, delegate: delegate)
        case let .moveToOrganization(cipher):
            showMoveToOrganization(cipher: cipher, delegate: context as? MoveToOrganizationProcessorDelegate)
        case .setupTotpManual:
            guard let delegate = context as? AuthenticatorKeyCaptureDelegate else { return }
            showManualTotp(delegate: delegate)
        case let .viewItem(id):
            showViewItem(id: id, delegate: context as? CipherItemOperationDelegate)
        case .scanCode:
            Task {
                await navigate(asyncTo: .scanCode, context: context)
            }
        }
    }

    func navigate(asyncTo route: VaultItemRoute, context: AnyObject?) async {
        guard case .scanCode = route else {
            navigate(to: route, context: context)
            return
        }
        guard let delegate = context as? AuthenticatorKeyCaptureDelegate else { return }
        await showCamera(delegate: delegate)
    }

    func start() {}

    // MARK: Private Methods

    /// Present a child `VaultItemCoordinator` on top of the existing coordinator.
    ///
    /// Presenting a view on top of an already presented view within the same coordinator causes
    /// problems when dismissing only the top view. So instead, present a new coordinator and
    /// show the view to navigate to within that coordinator's navigator.
    ///
    /// - Parameter route: The route to navigate to in the presented coordinator.
    ///
    private func presentChildVaultItemCoordinator(route: VaultItemRoute, context: AnyObject?) {
        let navigationController = UINavigationController()
        let coordinator = module.makeVaultItemCoordinator(stackNavigator: navigationController)
        coordinator.navigate(to: route, context: context)
        coordinator.start()
        stackNavigator.present(navigationController)
    }

    /// Shows the add item screen.
    ///
    /// - Parameters:
    ///   - type: An optional `CipherType` to initialize this view with.
    ///   - allowTypeSelection: Whether the user should be able to select the type of item to add.
    ///   - hasPremium: Whether the user has premium,
    ///   - uri: A URI string used to populate the add item screen.
    ///   - delegate: A `CipherItemOperationDelegate` delegate that is notified when specific circumstances
    ///     in the add/edit/delete item view have occurred.
    ///
    private func showAddItem(
        for type: CipherType?,
        allowTypeSelection: Bool,
        hasPremium: Bool,
        uri: String?,
        delegate: CipherItemOperationDelegate?
    ) {
        let state = CipherItemState(
            addItem: type ?? .login,
            allowTypeSelection: allowTypeSelection,
            hasPremium: hasPremium,
            uri: uri
        )
        let processor = AddEditItemProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: state
        )
        let store = Store(processor: processor)
        let view = AddEditItemView(store: store)
        stackNavigator.replace(view)
    }

    /// Shows the clone item screen.
    ///
    /// - Parameters:
    ///   - cipherView: A `CipherView` to initialize this view with.
    ///   - delegate: A `CipherItemOperationDelegate` delegate that is notified when specific circumstances
    ///    in the add/edit/delete item view have occurred.
    ///
    private func showCloneItem(for cipherView: CipherView, delegate: CipherItemOperationDelegate?) {
        Task {
            let hasPremium = await (
                try? services.vaultRepository.doesActiveAccountHavePremium()
            ) ?? false
            let state = CipherItemState(cloneItem: cipherView, hasPremium: hasPremium)
            if stackNavigator.isEmpty {
                let processor = AddEditItemProcessor(
                    coordinator: asAnyCoordinator(),
                    delegate: delegate,
                    services: services,
                    state: state
                )
                let store = Store(processor: processor)
                let view = AddEditItemView(store: store)
                stackNavigator.replace(view)
            } else {
                presentChildVaultItemCoordinator(route: .cloneItem(cipher: cipherView), context: delegate)
            }
        }
    }

    /// Shows the move to organization screen.
    ///
    private func showEditCollections(cipher: CipherView, delegate: EditCollectionsProcessorDelegate?) {
        let processor = EditCollectionsProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: EditCollectionsState(cipher: cipher)
        )
        let view = EditCollectionsView(store: Store(processor: processor))
        let hostingController = UIHostingController(rootView: view)
        stackNavigator.present(UINavigationController(rootViewController: hostingController))
    }

    /// Shows the edit item screen.
    /// .
    /// - Parameters:
    ///   - cipherView: The `CipherView` to edit.
    ///   - hasPremium: Whether the user has premium.
    ///   - delegate: The delegate for the view.
    ///
    private func showEditItem(for cipherView: CipherView, hasPremium: Bool, delegate: CipherItemOperationDelegate?) {
        if stackNavigator.isEmpty {
            guard let state = CipherItemState(existing: cipherView, hasPremium: hasPremium) else { return }

            let processor = AddEditItemProcessor(
                coordinator: asAnyCoordinator(),
                delegate: delegate,
                services: services,
                state: state
            )
            let store = Store(processor: processor)
            let view = AddEditItemView(store: store)
            stackNavigator.replace(view)
        } else {
            presentChildVaultItemCoordinator(route: .editItem(cipherView, hasPremium), context: delegate)
        }
    }

    /// Shows the totp camera setup screen.
    ///
    private func showCamera(delegate: AuthenticatorKeyCaptureDelegate) async {
        let navigationController = UINavigationController()
        let coordinator = AuthenticatorKeyCaptureCoordinator(
            delegate: delegate,
            services: services,
            stackNavigator: navigationController
        )
        coordinator.start()
        await coordinator.navigate(asyncTo: .scanCode)
        stackNavigator.present(navigationController, overFullscreen: true)
    }

    /// Shows the totp manual setup screen.
    ///
    private func showManualTotp(delegate: AuthenticatorKeyCaptureDelegate) {
        let navigationController = UINavigationController()
        let coordinator = AuthenticatorKeyCaptureCoordinator(
            delegate: delegate,
            services: services,
            stackNavigator: navigationController
        ).asAnyCoordinator()
        coordinator.start()
        coordinator.navigate(to: .manualKeyEntry, context: nil)
        stackNavigator.present(navigationController)
    }

    /// Shows the move to organization screen.
    ///
    private func showMoveToOrganization(cipher: CipherView, delegate: MoveToOrganizationProcessorDelegate?) {
        let processor = MoveToOrganizationProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: MoveToOrganizationState(cipher: cipher)
        )
        let view = MoveToOrganizationView(store: Store(processor: processor))
        let hostingController = UIHostingController(rootView: view)
        stackNavigator.present(UINavigationController(rootViewController: hostingController))
    }

    /// Shows the generator screen for the the specified type.
    ///
    /// - Parameters:
    ///   - type: The type to generate.
    ///   - emailWebsite: An optional website host used to generate usernames.
    ///   - delegate: The delegate for this generator flow.
    ///
    private func showGenerator(
        for type: GeneratorType,
        emailWebsite: String?,
        delegate: GeneratorCoordinatorDelegate
    ) {
        let navigationController = UINavigationController()
        let coordinator = module.makeGeneratorCoordinator(
            delegate: delegate,
            stackNavigator: navigationController
        ).asAnyCoordinator()
        coordinator.start()
        coordinator.navigate(to: .generator(staticType: type, emailWebsite: emailWebsite))
        stackNavigator.present(navigationController)
    }

    /// Shows the view item screen.
    ///
    /// - Parameters:
    ///   - id: The id of the item to show.
    ///   - delegate: The delegate.
    ///
    private func showViewItem(id: String, delegate: CipherItemOperationDelegate?) {
        let processor = ViewItemProcessor(
            coordinator: self,
            delegate: delegate,
            itemId: id,
            services: services,
            state: ViewItemState()
        )
        let store = Store(processor: processor)
        let view = ViewItemView(store: store)
        stackNavigator.replace(view)
    }
}

extension View {
    @ViewBuilder var navStackWrapped: some View {
        if #available(iOSApplicationExtension 16.0, *) {
            NavigationStack { self }
        } else {
            NavigationView { self }
                .navigationViewStyle(.stack)
        }
    }
}
