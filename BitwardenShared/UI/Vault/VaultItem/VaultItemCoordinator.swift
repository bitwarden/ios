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

    // MARK: Private Properties

    /// The coordinator currently being displayed.
    private var childCoordinator: AnyObject?

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
        case let .addItem(group):
            showAddItem(for: group.flatMap(CipherType.init))
        case let .alert(alert):
            stackNavigator.present(alert)
        case let .dismiss(onDismiss):
            stackNavigator.dismiss(animated: true, completion: {
                onDismiss?.action()
            })
        case let .editItem(cipher: cipher):
            showEditItem(for: cipher, context: context)
        case let .generator(type, emailWebsite):
            guard let delegate = context as? GeneratorCoordinatorDelegate else { return }
            showGenerator(for: type, emailWebsite: emailWebsite, delegate: delegate)
        case let .moveToOrganization(cipher):
            showMoveToOrganization(cipher: cipher, delegate: context as? MoveToOrganizationProcessorDelegate)
        case .setupTotpManual:
            guard let delegate = context as? AuthenticatorKeyCaptureDelegate else { return }
            showManualTotp(delegate: delegate)
        case let .viewItem(id):
            showViewItem(id: id)
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

    /// Shows the add item screen.
    ///
    /// - Parameter type: An optional `CipherType` to initialize this view with.
    ///
    private func showAddItem(for type: CipherType?) {
        Task {
            let hasPremium = await (try? services.vaultRepository.doesActiveAccountHavePremium())
                ?? false
            let state = CipherItemState(addItem: type ?? .login, hasPremium: hasPremium)
            let processor = AddEditItemProcessor(
                coordinator: asAnyCoordinator(),
                services: services,
                state: state
            )
            let store = Store(processor: processor)
            let view = AddEditItemView(store: store)
            stackNavigator.replace(view)
        }
    }

    /// Shows the edit item screen.
    ///
    /// - Parameter cipherView: A `CipherView` to initialize this view with.
    ///
    private func showEditItem(for cipherView: CipherView, context: AnyObject?) {
        Task {
            let hasPremium = await (try? services.vaultRepository.doesActiveAccountHavePremium())
                ?? false
            guard let state = CipherItemState(existing: cipherView, hasPremium: hasPremium) else { return }
            if context is VaultItemCoordinator {
                let processor = AddEditItemProcessor(
                    coordinator: asAnyCoordinator(),
                    services: services,
                    state: state
                )
                let store = Store(processor: processor)
                let view = AddEditItemView(store: store)
                stackNavigator.replace(view)
            } else {
                let navigationController = UINavigationController()
                let coordinator = module.makeVaultItemCoordinator(stackNavigator: navigationController)
                coordinator.start()
                coordinator.navigate(to: .editItem(cipher: cipherView), context: self)
                stackNavigator.present(navigationController)
            }
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
