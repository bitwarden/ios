import SwiftUI

// MARK: - SettingsCoordinatorDelegate

/// An object that is signaled when specific circumstances in the application flow have been encountered.
///
@MainActor
public protocol SettingsCoordinatorDelegate: AnyObject {
    func didDeleteAccount(otherAccounts: [Account]?)

    /// Called when the user locks their vault.
    ///
    /// - Parameters:
    ///   - account: The user's account.
    ///
    func didLockVault(account: Account)

    /// Called when the user has been logged out.
    ///
    func didLogout()
}

// MARK: - SettingsCoordinator

/// A coordinator that manages navigation in the settings tab.
///
final class SettingsCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasAccountAPIService
        & HasBaseUrlService
        & HasBiometricsService
        & HasClientAuth
        & HasErrorReporter
        & HasSettingsRepository
        & HasStateService
        & HasTwoStepLoginService
        & HasVaultRepository
        & HasVaultTimeoutService

    // MARK: Properties

    /// The delegate for this coordinator, used to notify when the user logs out.
    private weak var delegate: SettingsCoordinatorDelegate?

    /// The services used by this coordinator.
    let services: Services

    /// The stack navigator that is managed by this coordinator.
    let stackNavigator: StackNavigator

    // MARK: Initialization

    /// Creates a new `SettingsCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for this coordinator, used to notify when the user logs out.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        delegate: SettingsCoordinatorDelegate,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.delegate = delegate
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func navigate(to route: SettingsRoute, context: AnyObject?) {
        switch route {
        case .accountSecurity:
            showAccountSecurity()
        case let .alert(alert):
            stackNavigator.present(alert)
        case .autoFill:
            showAutoFill()
        case .deleteAccount:
            showDeleteAccount()
        case let .didDeleteAccount(otherAccounts):
            stackNavigator.dismiss()
            delegate?.didDeleteAccount(otherAccounts: otherAccounts ?? nil)
        case .dismiss:
            stackNavigator.dismiss()
        case let .lockVault(account):
            delegate?.didLockVault(account: account)
        case .logout:
            delegate?.didLogout()
        case .other:
            showOtherScreen()
        case .settings:
            showSettings()
        }
    }

    func start() {
        navigate(to: .settings)
    }

    // MARK: Private Methods

    /// Shows the account security screen.
    ///
    private func showAccountSecurity() {
        let processor = AccountSecurityProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: AccountSecurityState()
        )

        let view = AccountSecurityView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator.push(viewController)
    }

    /// Shows the auto-fill screen.
    ///
    private func showAutoFill() {
        let processor = AutoFillProcessor(
            coordinator: asAnyCoordinator(),
            state: AutoFillState()
        )
        let view = AutoFillView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator.push(viewController)
    }

    /// Shows the delete account screen.
    ///
    private func showDeleteAccount() {
        let processor = DeleteAccountProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: DeleteAccountState()
        )
        let view = DeleteAccountView(store: Store(processor: processor))
        let navController = UINavigationController(rootViewController: UIHostingController(rootView: view))
        stackNavigator.present(navController)
    }

    /// Shows the other settings screen.
    ///
    private func showOtherScreen() {
        let processor = OtherSettingsProcessor(
            coordinator: asAnyCoordinator(),
            state: OtherSettingsState()
        )

        let view = OtherSettingsView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator.push(viewController)
    }

    /// Shows the settings screen.
    ///
    private func showSettings() {
        let processor = SettingsProcessor(
            coordinator: asAnyCoordinator(),
            state: SettingsState()
        )
        let view = SettingsView(store: Store(processor: processor))
        stackNavigator.push(view)
    }
}
