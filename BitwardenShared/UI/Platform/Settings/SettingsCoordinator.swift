import BitwardenSdk
import SwiftUI

// swiftlint:disable file_length

// MARK: - SettingsCoordinatorDelegate

/// An object that is signaled when specific circumstances in the application flow have been encountered.
///
@MainActor
public protocol SettingsCoordinatorDelegate: AnyObject {
    /// Called when the active user's account has been deleted.
    ///
    func didDeleteAccount()

    /// Called when the user has requested an account vault be locked.
    ///
    /// - Parameter userId: The id of the user to lock.
    ///
    func lockVault(userId: String?)

    /// Called when the user has requested an account be logged out.
    ///
    /// - Parameters:
    ///   - userId: The id of the account to log out.
    ///   - userInitiated: Did a user action initiate this logout?
    ///
    func logout(userId: String?, userInitiated: Bool)

    /// Called when the user requests an account switch.
    ///
    /// - Parameters:
    ///   - isUserInitiated: Did the user trigger the account switch?
    ///   - userId: The user Id of the selected account.
    ///
    func switchAccount(isAutomatic: Bool, userId: String)
}

// MARK: - SettingsCoordinator

/// A coordinator that manages navigation in the settings tab.
///
final class SettingsCoordinator: Coordinator, HasStackNavigator { // swiftlint:disable:this type_body_length
    // MARK: Types

    /// The module types required by this coordinator for creating child coordinators.
    typealias Module = LoginRequestModule

    typealias Services = HasAccountAPIService
        & HasAuthRepository
        & HasAuthService
        & HasBiometricsRepository
        & HasClientAuth
        & HasClientExporters
        & HasErrorReporter
        & HasExportVaultService
        & HasPasteboardService
        & HasPolicyService
        & HasSettingsRepository
        & HasStateService
        & HasTimeProvider
        & HasTwoStepLoginService
        & HasVaultRepository
        & HasVaultTimeoutService

    // MARK: Private Properties

    /// The delegate for this coordinator, used to notify when the user logs out.
    private weak var delegate: SettingsCoordinatorDelegate?

    /// The module used to create child coordinators.
    private let module: Module

    /// The services used by this coordinator.
    private let services: Services

    // MARK: Properties

    /// The stack navigator that is managed by this coordinator.
    private(set) weak var stackNavigator: StackNavigator?

    // MARK: Initialization

    /// Creates a new `SettingsCoordinator`.
    ///
    /// - Parameters:
    ///   - delegate: The delegate for this coordinator, used to notify when the user logs out.
    ///   - module: The module used to create child coordinators.
    ///   - services: The services used by this coordinator.
    ///   - stackNavigator: The stack navigator that is managed by this coordinator.
    ///
    init(
        delegate: SettingsCoordinatorDelegate,
        module: Module,
        services: Services,
        stackNavigator: StackNavigator
    ) {
        self.delegate = delegate
        self.module = module
        self.services = services
        self.stackNavigator = stackNavigator
    }

    // MARK: Methods

    func handleEvent(_ event: SettingsEvent, context: AnyObject?) async {
        switch event {
        case let .authAction(action):
            switch action {
            case let .lockVault(userId):
                delegate?.lockVault(userId: userId)
            case let .logout(userId, userInitiated):
                delegate?.logout(userId: userId, userInitiated: userInitiated)
            case let .switchAccount(isAutomatic, userId):
                delegate?.switchAccount(isAutomatic: isAutomatic, userId: userId)
            }
        case .didDeleteAccount:
            stackNavigator?.dismiss {
                self.delegate?.didDeleteAccount()
            }
        }
    }

    func navigate(to route: SettingsRoute, context: AnyObject?) {
        switch route {
        case .about:
            showAbout()
        case .accountSecurity:
            showAccountSecurity()
        case let .addEditFolder(folder):
            showAddEditFolder(folder, delegate: context as? AddEditFolderDelegate)
        case let .alert(alert):
            stackNavigator?.present(alert)
        case .appearance:
            showAppearance()
        case .appExtension:
            showAppExtension()
        case .appExtensionSetup:
            showAppExtensionSetup(delegate: context as? AppExtensionSetupDelegate)
        case .autoFill:
            showAutoFill()
        case .deleteAccount:
            showDeleteAccount()
        case .dismiss:
            stackNavigator?.dismiss()
        case .exportVault:
            showExportVault()
        case .folders:
            showFolders()
        case let .loginRequest(loginRequest):
            showLoginRequest(loginRequest, delegate: context as? LoginRequestDelegate)
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
        case let .shareExportedVault(fileURL):
            showExportedVaultURL(fileURL)
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
        stackNavigator?.push(viewController, navigationTitle: Localizations.about)
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
        stackNavigator?.push(viewController, navigationTitle: Localizations.accountSecurity)
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
        stackNavigator?.present(navController)
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
        stackNavigator?.push(viewController, navigationTitle: Localizations.appearance)
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
        stackNavigator?.push(viewController, navigationTitle: Localizations.appExtension)
    }

    /// Shows the app extension setup screen.
    ///
    /// - Parameter delegate: The `AppExtensionSetupDelegate` to notify when the user interacts with
    ///     the extension.
    ///
    private func showAppExtensionSetup(delegate: AppExtensionSetupDelegate?) {
        let extensionItem = NSExtensionItem()
        extensionItem.attachments = [
            NSItemProvider(
                item: "" as NSString,
                typeIdentifier: Constants.UTType.appExtensionSetup
            ),
        ]
        let viewController = UIActivityViewController(activityItems: [extensionItem], applicationActivities: nil)
        viewController.completionWithItemsHandler = { activityType, completed, _, _ in
            delegate?.didDismissExtensionSetup(
                enabled: completed &&
                    activityType?.rawValue == Bundle.main.appExtensionIdentifier
            )
        }
        stackNavigator?.present(viewController)
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
        stackNavigator?.push(viewController, navigationTitle: Localizations.autofill)
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
        stackNavigator?.present(navController)
    }

    /// presents an activity contorller for an exported vault file URL.
    ///
    private func showExportedVaultURL(_ fileURL: URL) {
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        stackNavigator?.present(activityVC)
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
        stackNavigator?.present(navController)
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
        stackNavigator?.push(viewController, navigationTitle: Localizations.folders)
    }

    /// Shows the login request.
    ///
    /// - Parameters:
    ///   - loginRequest: The login request to display.
    ///   - delegate: The delegate.
    ///
    private func showLoginRequest(_ loginRequest: LoginRequest, delegate: LoginRequestDelegate?) {
        let navigationController = UINavigationController()
        let coordinator = module.makeLoginRequestCoordinator(stackNavigator: navigationController)
        coordinator.start()
        coordinator.navigate(to: .loginRequest(loginRequest), context: delegate)
        stackNavigator?.present(navigationController)
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
        stackNavigator?.push(viewController, navigationTitle: Localizations.other)
    }

    /// Shows the password auto-fill screen.
    ///
    private func showPasswordAutoFill() {
        let view = PasswordAutoFillView()
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator?.push(viewController, navigationTitle: Localizations.passwordAutofill)
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
        stackNavigator?.present(navController)
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
        stackNavigator?.present(navController)
    }

    /// Shows the settings screen.
    ///
    private func showSettings() {
        let processor = SettingsProcessor(
            coordinator: asAnyCoordinator(),
            state: SettingsState()
        )
        let view = SettingsView(store: Store(processor: processor))
        stackNavigator?.push(view)
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
        stackNavigator?.push(viewController, navigationTitle: Localizations.vault)
    }
}
