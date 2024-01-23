import BitwardenSdk
import SwiftUI

// MARK: - SettingsCoordinatorDelegate

/// An object that is signaled when specific circumstances in the application flow have been encountered.
///
@MainActor
public protocol SettingsCoordinatorDelegate: AnyObject {
    /// Called when the user's account has been deleted.
    ///
    /// - Parameter otherAccounts: An optional array of the user's other accounts.
    ///
    func didDeleteAccount(otherAccounts: [Account]?)

    /// Called when the user locks their vault.
    ///
    /// - Parameter account: The user's account.
    ///
    func didLockVault(account: Account)

    /// Called when the user has been logged out.
    ///
    /// - Parameters:
    ///   - userInitiated: Did a user action initiate this logout.
    ///   - otherAccounts: An optional array of the user's other accounts.
    ///
    func didLogout(userInitiated: Bool, otherAccounts: [Account]?)
}

// MARK: - SettingsCoordinator

/// A coordinator that manages navigation in the settings tab.
///
final class SettingsCoordinator: Coordinator, HasStackNavigator {
    // MARK: Types

    typealias Services = HasAccountAPIService
        & HasAuthRepository
        & HasAuthService
        & HasBiometricsService
        & HasClientAuth
        & HasErrorReporter
        & HasPasteboardService
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
        case .about:
            showAbout()
        case .accountSecurity:
            showAccountSecurity()
        case let .addEditFolder(folder):
            showAddEditFolder(folder, delegate: context as? AddEditFolderDelegate)
        case let .alert(alert):
            stackNavigator.present(alert)
        case .appearance:
            showAppearance()
        case .appExtension:
            showAppExtension()
        case .autoFill:
            showAutoFill()
        case .deleteAccount:
            showDeleteAccount()
        case let .didDeleteAccount(otherAccounts):
            stackNavigator.dismiss {
                self.delegate?.didDeleteAccount(otherAccounts: otherAccounts ?? nil)
            }
        case .dismiss:
            stackNavigator.dismiss()
        case .exportVault:
            showExportVault()
        case .folders:
            showFolders()
        case let .lockVault(account, _):
            delegate?.didLockVault(account: account)
        case let .logout(userInitiated):
            Task {
                let accounts = try? await services.stateService.getAccounts()
                delegate?.didLogout(userInitiated: userInitiated, otherAccounts: accounts)
            }
        case .other:
            showOtherScreen()
        case .passwordAutoFill:
            showPasswordAutoFill()
        case .pendingLoginRequests:
            showPendingLoginRequests()
        case let .selectLanguage(currentLanguage: currentLanguage):
            showSelectLanguage(currentLanguage: currentLanguage, delegate: context as? SelectLanguageDelegate)
        case .settings:
            showSettings()
        case .vault:
            showVault()
        }
    }

    func start() {
        navigate(to: .settings)
    }

    // MARK: Private Methods

    /// Shows the about screen.
    ///
    private func showAbout() {
        let processor = AboutProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: AboutState()
        )

        let view = AboutView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator.push(viewController, navigationTitle: Localizations.about)
    }

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
        stackNavigator.push(viewController, navigationTitle: Localizations.accountSecurity)
    }

    /// Shows the add or edit folder screen.
    ///
    /// - Parameter folder: The existing folder to edit, if applicable.
    ///
    private func showAddEditFolder(_ folder: FolderView?, delegate: AddEditFolderDelegate?) {
        let mode: AddEditFolderState.Mode = if let folder { .edit(folder) } else { .add }
        let processor = AddEditFolderProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: AddEditFolderState(folderName: folder?.name ?? "", mode: mode)
        )
        let view = AddEditFolderView(store: Store(processor: processor))
        let navController = UINavigationController(rootViewController: UIHostingController(rootView: view))
        stackNavigator.present(navController)
    }

    /// Shows the appearance screen.
    ///
    private func showAppearance() {
        let processor = AppearanceProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: AppearanceState()
        )

        let view = AppearanceView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator.push(viewController, navigationTitle: Localizations.appearance)
    }

    /// Shows the app extension screen.
    ///
    private func showAppExtension() {
        let processor = AppExtensionProcessor(
            coordinator: asAnyCoordinator(),
            state: AppExtensionState()
        )
        let view = AppExtensionView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator.push(viewController, navigationTitle: Localizations.appExtension)
    }

    /// Shows the auto-fill screen.
    ///
    private func showAutoFill() {
        let processor = AutoFillProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: AutoFillState()
        )
        let view = AutoFillView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator.push(viewController, navigationTitle: Localizations.autofill)
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

    /// Shows the export vault screen.
    ///
    private func showExportVault() {
        let processor = ExportVaultProcessor(
            coordinator: asAnyCoordinator(),
            services: services
        )
        let view = ExportVaultView(store: Store(processor: processor))
        let navController = UINavigationController(rootViewController: UIHostingController(rootView: view))
        stackNavigator.present(navController)
    }

    /// Shows the folders screen.
    ///
    private func showFolders() {
        let processor = FoldersProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: FoldersState()
        )
        let view = FoldersView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator.push(viewController, navigationTitle: Localizations.folders)
    }

    /// Shows the other settings screen.
    ///
    private func showOtherScreen() {
        let processor = OtherSettingsProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: OtherSettingsState()
        )

        let view = OtherSettingsView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator.push(viewController, navigationTitle: Localizations.other)
    }

    /// Shows the password auto-fill screen.
    ///
    private func showPasswordAutoFill() {
        let view = PasswordAutoFillView()
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator.push(viewController, navigationTitle: Localizations.passwordAutofill)
    }

    /// Shows the pending login requests screen.
    ///
    private func showPendingLoginRequests() {
        let processor = PendingRequestsProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: PendingRequestsState()
        )
        let view = PendingRequestsView(store: Store(processor: processor))
        let navController = UINavigationController(rootViewController: UIHostingController(rootView: view))
        stackNavigator.present(navController)
    }

    /// Shows the select language screen.
    ///
    private func showSelectLanguage(currentLanguage: LanguageOption, delegate: SelectLanguageDelegate?) {
        let processor = SelectLanguageProcessor(
            coordinator: asAnyCoordinator(),
            delegate: delegate,
            services: services,
            state: SelectLanguageState(currentLanguage: currentLanguage)
        )
        let view = SelectLanguageView(store: Store(processor: processor))
        let navController = UINavigationController(rootViewController: UIHostingController(rootView: view))
        stackNavigator.present(navController)
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

    /// Shows the vault screen.
    ///
    private func showVault() {
        let processor = VaultSettingsProcessor(
            coordinator: asAnyCoordinator(),
            state: VaultSettingsState()
        )
        let view = VaultSettingsView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator.push(viewController, navigationTitle: Localizations.vault)
    }
}
