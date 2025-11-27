import AuthenticationServices
import BitwardenKit
import BitwardenResources
import BitwardenSdk
import SwiftUI

// swiftlint:disable file_length

// MARK: - SettingsCoordinatorDelegate

/// An object that is signaled when specific circumstances in the application flow have been encountered.
///
@MainActor
public protocol SettingsCoordinatorDelegate: AnyObject {
    /// Called when the user completes the import navigation flow and should be navigated to the vault tab.
    ///
    func didCompleteLoginsImport()

    /// Called when the active user's account has been deleted.
    ///
    func didDeleteAccount()

    /// Called when the user has requested an account vault be locked.
    /// - Parameters:
    ///   - userId: The user Id of the selected account. Defaults to the active user id if nil.
    ///   - isManuallyLocking: Whether the user is manually locking the account.
    ///
    func lockVault(userId: String?, isManuallyLocking: Bool)

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
    typealias Module = AddEditFolderModule
        & AuthModule
        & ExportCXFModule
        & FlightRecorderModule
        & ImportLoginsModule
        & LoginRequestModule
        & NavigatorBuilderModule
        & PasswordAutoFillModule
        & SelectLanguageModule

    typealias Services = HasAccountAPIService
        & HasAppInfoService
        & HasAuthRepository
        & HasAuthService
        & HasAutofillCredentialService
        & HasBiometricsRepository
        & HasConfigService
        & HasEnvironmentService
        & HasErrorAlertServices.ErrorAlertServices
        & HasErrorReporter
        & HasEventService
        & HasExportCXFCiphersRepository
        & HasExportVaultService
        & HasFlightRecorder
        & HasLanguageStateService
        & HasNotificationCenterService
        & HasPasteboardService
        & HasPolicyService
        & HasSettingsRepository
        & HasStateService
        & HasSystemDevice
        & HasTimeProvider
        & HasTwoStepLoginService
        & HasVaultRepository
        & HasVaultTimeoutService
        & HasWatchService

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
        delegate: SettingsCoordinatorDelegate?,
        module: Module,
        services: Services,
        stackNavigator: StackNavigator,
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
            case let .lockVault(userId, isManuallyLocking):
                delegate?.lockVault(userId: userId, isManuallyLocking: isManuallyLocking)
            case let .logout(userId, userInitiated):
                delegate?.logout(userId: userId, userInitiated: userInitiated)
            case let .switchAccount(isAutomatic, userId, _):
                delegate?.switchAccount(isAutomatic: isAutomatic, userId: userId)
            }
        case .didDeleteAccount:
            stackNavigator?.dismiss {
                self.delegate?.didDeleteAccount()
            }
        }
    }

    func navigate(to route: SettingsRoute, context: AnyObject?) { // swiftlint:disable:this function_body_length
        switch route {
        case .about:
            showAbout()
        case .accountSecurity:
            showAccountSecurity()
        case let .addEditFolder(folder):
            showAddEditFolder(folder, delegate: context as? AddEditFolderDelegate)
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
            Task {
                await showExportVault()
            }
        case .exportVaultToApp:
            showExportVaultToApp()
        case .exportVaultToFile:
            showExportVaultToFile()
        case let .flightRecorder(route):
            showFlightRecorder(route: route)
        case .folders:
            showFolders()
        case .importLogins:
            showImportLogins()
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
        case let .settings(presentationMode):
            showSettings(presentationMode: presentationMode)
        case let .shareURL(url):
            showShareSheet([url])
        case .vault:
            showVault()
        case .vaultUnlockSetup:
            showAuthCoordinator(route: .vaultUnlockSetup(.settings))
        }
    }

    func start() {
        navigate(to: .settings(.tab))
    }

    // MARK: Private Methods

    /// Shows the about screen.
    ///
    private func showAbout() {
        let processor = AboutProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: AboutState(),
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
            state: AccountSecurityState(),
            vaultUnlockSetupHelper: DefaultVaultUnlockSetupHelper(services: services),
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
        let navigationController = module.makeNavigationController()
        let coordinator = module.makeAddEditFolderCoordinator(stackNavigator: navigationController)
        coordinator.start()
        coordinator.navigate(to: .addEditFolder(folder: folder), context: delegate)

        stackNavigator?.present(navigationController)
    }

    /// Shows the appearance screen.
    ///
    private func showAppearance() {
        let processor = AppearanceProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: AppearanceState(),
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
            state: AppExtensionState(),
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
                typeIdentifier: Constants.UTType.appExtensionSetup,
            ),
        ]
        let viewController = UIActivityViewController(activityItems: [extensionItem], applicationActivities: nil)
        viewController.completionWithItemsHandler = { activityType, completed, _, _ in
            delegate?.didDismissExtensionSetup(
                enabled: completed &&
                    activityType?.rawValue == Bundle.main.appExtensionIdentifier,
            )
        }
        stackNavigator?.present(viewController)
    }

    /// Navigates to the specified auth coordinator route within the existing navigator.
    ///
    /// - Parameter route: The auth route to navigate to.
    ///
    private func showAuthCoordinator(route: AuthRoute) {
        guard let stackNavigator else { return }
        let coordinator = module.makeAuthCoordinator(
            delegate: nil,
            rootNavigator: nil,
            stackNavigator: stackNavigator,
        )
        coordinator.navigate(to: route)
    }

    /// Shows the auto-fill screen.
    ///
    private func showAutoFill() {
        let processor = AutoFillProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: AutoFillState(),
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
            state: DeleteAccountState(),
        )
        stackNavigator?.present(DeleteAccountView(store: Store(processor: processor)))
    }

    /// Shows the share sheet to share one or more items.
    ///
    /// - Parameter items: The items to share.
    ///
    private func showShareSheet(_ items: [Any]) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        stackNavigator?.present(activityVC)
    }

    /// Shows the export vault screen.
    ///
    @MainActor
    private func showExportVault() async {
        guard await services.configService.getFeatureFlag(.cxpExportMobile) else {
            navigate(to: .exportVaultToFile)
            return
        }

        let processor = ExportSettingsProcessor(coordinator: asAnyCoordinator())
        let view = ExportSettingsView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator?.push(viewController, navigationTitle: Localizations.exportVault)
    }

    /// Shows the export vault to file screen.
    ///
    private func showExportVaultToFile() {
        let processor = ExportVaultProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
        )
        stackNavigator?.present(ExportVaultView(store: Store(processor: processor)))
    }

    /// Shows the export vault to another app screen (Credential Exchange flow).
    ///
    private func showExportVaultToApp() {
        let navigationController = module.makeNavigationController()
        let coordinator = module.makeExportCXFCoordinator(
            stackNavigator: navigationController,
        )
        coordinator.start()
        stackNavigator?.present(navigationController)
    }

    /// Shows a flight recorder view.
    ///
    /// - Parameter route: A `FlightRecorderRoute` to navigate to.
    ///
    private func showFlightRecorder(route: FlightRecorderRoute) {
        guard let stackNavigator else { return }
        let coordinator = module.makeFlightRecorderCoordinator(stackNavigator: stackNavigator)
        coordinator.start()
        coordinator.navigate(to: route)
    }

    /// Shows the folders screen.
    ///
    private func showFolders() {
        let processor = FoldersProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: FoldersState(),
        )
        let view = FoldersView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator?.push(viewController, navigationTitle: Localizations.folders)
    }

    /// Shows the import login items screen.
    ///
    private func showImportLogins() {
        let navigationController = module.makeNavigationController()
        navigationController.modalPresentationStyle = .overFullScreen
        let coordinator = module.makeImportLoginsCoordinator(
            delegate: self,
            stackNavigator: navigationController,
        )
        coordinator.start()
        coordinator.navigate(to: .importLogins(.settings))

        stackNavigator?.present(navigationController)
    }

    /// Shows the login request.
    ///
    /// - Parameters:
    ///   - loginRequest: The login request to display.
    ///   - delegate: The delegate.
    ///
    private func showLoginRequest(_ loginRequest: LoginRequest, delegate: LoginRequestDelegate?) {
        let navigationController = module.makeNavigationController()
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
            state: OtherSettingsState(),
        )
        let view = OtherSettingsView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator?.push(viewController, navigationTitle: Localizations.other)
    }

    /// Shows the password auto-fill screen.
    ///
    private func showPasswordAutoFill() {
        guard let stackNavigator else { return }
        let coordinator = module.makePasswordAutoFillCoordinator(
            delegate: nil,
            stackNavigator: stackNavigator,
        )
        coordinator.start()
        coordinator.navigate(to: .passwordAutofill(mode: .settings))
    }

    /// Shows the pending login requests screen.
    ///
    private func showPendingLoginRequests() {
        let processor = PendingRequestsProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: PendingRequestsState(),
        )
        stackNavigator?.present(PendingRequestsView(store: Store(processor: processor)))
    }

    /// Shows the select language screen.
    ///
    private func showSelectLanguage(
        currentLanguage: LanguageOption,
        delegate: SelectLanguageDelegate?,
    ) {
        guard let stackNavigator else { return }
        let coordinator = module.makeSelectLanguageCoordinator(
            stackNavigator: stackNavigator,
        )
        coordinator.start()
        coordinator.navigate(to: .open(currentLanguage: currentLanguage), context: delegate)
    }

    /// Shows the settings screen.
    ///
    private func showSettings(presentationMode: SettingsPresentationMode) {
        let processor = SettingsProcessor(
            coordinator: asAnyCoordinator(),
            delegate: self,
            services: services,
            state: SettingsState(presentationMode: presentationMode),
        )
        let view = SettingsView(store: Store(processor: processor))
        stackNavigator?.replace(view, animated: false)
    }

    /// Shows the vault screen.
    ///
    private func showVault() {
        let processor = VaultSettingsProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: VaultSettingsState(),
        )
        let view = VaultSettingsView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        viewController.navigationItem.largeTitleDisplayMode = .never
        stackNavigator?.push(viewController, navigationTitle: Localizations.vault)
    }
}

// MARK: - HasErrorAlertServices

extension SettingsCoordinator: HasErrorAlertServices {
    var errorAlertServices: ErrorAlertServices { services }
}

// MARK: - ImportLoginsCoordinatorDelegate

extension SettingsCoordinator: ImportLoginsCoordinatorDelegate {
    func didCompleteLoginsImport() {
        stackNavigator?.dismiss {
            self.delegate?.didCompleteLoginsImport()
        }
    }
}

// MARK: - SettingsProcessorDelegate

extension SettingsCoordinator: SettingsProcessorDelegate {
    func updateSettingsTabBadge(_ badgeValue: String?) {
        stackNavigator?.rootViewController?.tabBarItem.badgeValue = badgeValue
    }
}
