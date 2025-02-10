import BitwardenSdk
import SwiftUI

// MARK: - VaultCoordinatorDelegate

/// An object that is signaled when specific circumstances in the application flow have been encountered.
///
@MainActor
public protocol VaultCoordinatorDelegate: AnyObject {
    /// Called when the user locks their vault.
    ///
    /// - Parameters:
    ///   - userId: The user Id of the selected account. Defaults to the active user id if nil.
    ///   - isManuallyLocking: Whether the user is manually locking the account.
    ///
    func lockVault(userId: String?, isManuallyLocking: Bool)

    /// Called when the user has been logged out.
    ///
    /// - Parameters:
    ///   - userId: The id of the account to log out.
    ///   - userInitiated: Did a user action initiate this logout?
    ///
    func logout(userId: String?, userInitiated: Bool)

    /// Called when the user taps add account.
    ///
    func didTapAddAccount()

    /// Called when the user taps selects alternate account.
    ///
    ///  - Parameter userId: The userId of the selected account.
    ///
    func didTapAccount(userId: String)

    /// Present the login request view.
    ///
    /// - Parameter loginRequest: The login request.
    ///
    func presentLoginRequest(_ loginRequest: LoginRequest)

    /// When the user requests an account switch.
    ///
    /// - Parameters:
    ///   - userId: The user Id of the account.
    ///   - isAutomatic: Did the system trigger the account switch?
    ///   - authCompletionRoute: An optional route that should be navigated to after switching
    ///     accounts and vault unlock
    ///
    func switchAccount(userId: String, isAutomatic: Bool, authCompletionRoute: AppRoute?)
}

// MARK: - VaultCoordinator

/// A coordinator that manages navigation in the vault tab.
///
final class VaultCoordinator: Coordinator, HasStackNavigator { // swiftlint:disable:this type_body_length
    // MARK: Types

    typealias Module = GeneratorModule
        & ImportCXFModule
        & ImportLoginsModule
        & TwoFactorNoticeModule
        & VaultItemModule

    typealias Services = HasApplication
        & HasAuthRepository
        & HasAuthService
        & HasAutofillCredentialService
        & HasCameraService
        & HasClientService
        & HasConfigService
        & HasEnvironmentService
        & HasErrorReporter
        & HasFido2CredentialStore
        & HasFido2UserInterfaceHelper
        & HasLocalAuthService
        & HasNotificationService
        & HasReviewPromptService
        & HasSettingsRepository
        & HasStateService
        & HasSyncService
        & HasTOTPExpirationManagerFactory
        & HasTextAutofillHelperFactory
        & HasTimeProvider
        & HasUserVerificationHelperFactory
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
    private(set) weak var stackNavigator: StackNavigator?

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

    func handleEvent(_ event: AuthAction, context: AnyObject?) async {
        switch event {
        case let .logout(userId, userInitiated):
            delegate?.logout(userId: userId, userInitiated: userInitiated)
        case let .lockVault(userId, isManuallyLocking):
            delegate?.lockVault(userId: userId, isManuallyLocking: isManuallyLocking)
        case let .switchAccount(isAutomatic, userId, authCompletionRoute):
            delegate?.switchAccount(
                userId: userId,
                isAutomatic: isAutomatic,
                authCompletionRoute: authCompletionRoute
            )
        }
    }

    func navigate(to route: VaultRoute, context: AnyObject?) { // swiftlint:disable:this function_body_length
        switch route {
        case .addAccount:
            delegate?.didTapAddAccount()
        case let .addItem(allowTypeSelection, group, newCipherOptions, organizationId):
            Task {
                let hasPremium = try? await services.vaultRepository.doesActiveAccountHavePremium()
                showVaultItem(
                    route: .addItem(
                        allowTypeSelection: allowTypeSelection,
                        group: group,
                        hasPremium: hasPremium ?? false,
                        newCipherOptions: newCipherOptions,
                        organizationId: organizationId
                    ),
                    delegate: context as? CipherItemOperationDelegate
                )
            }
        case .autofillList:
            showAutofillList()
        case let .autofillListForGroup(group):
            showAutofillListForGroup(group)
        case let .editItem(cipher):
            Task {
                let hasPremium = try? await services.vaultRepository.doesActiveAccountHavePremium()
                showVaultItem(
                    route: .editItem(cipher, hasPremium ?? false),
                    delegate: context as? CipherItemOperationDelegate
                )
            }
        case let .editItemFrom(id):
            Task {
                do {
                    guard let cipher = try await services.vaultRepository.fetchCipher(withId: id) else {
                        return
                    }
                    navigate(to: .editItem(cipher))
                } catch {
                    services.errorReporter.log(error: error)
                }
            }
        case .dismiss:
            stackNavigator?.dismiss()
        case let .group(group, filter):
            showGroup(group, filter: filter)
        case let .importCXF(cxfRoute):
            showImportCXF(route: cxfRoute)
        case .importLogins:
            showImportLogins()
        case .list:
            showList()
        case let .loginRequest(loginRequest):
            delegate?.presentLoginRequest(loginRequest)
        case let .twoFactorNotice(allowDelay, emailAddress):
            showTwoFactorNotice(allowDelay: allowDelay, emailAddress: emailAddress)
        case let .vaultItemSelection(totpKeyModel):
            showVaultItemSelection(totpKeyModel: totpKeyModel)
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
            state: VaultAutofillListState(
                iconBaseURL: services.environmentService.iconsURL
            )
        )
        let view = VaultAutofillListView(store: Store(processor: processor), timeProvider: services.timeProvider)
        stackNavigator?.replace(view)
    }

    /// Shows the autofill list screen for a specified group.
    ///
    private func showAutofillListForGroup(_ group: VaultListGroup) {
        let processor = VaultAutofillListProcessor(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: asAnyCoordinator(),
            services: services,
            state: VaultAutofillListState(
                group: group,
                iconBaseURL: services.environmentService.iconsURL
            )
        )
        let store = Store(processor: processor)
        let searchHandler = VaultAutofillSearchHandler(store: store)
        let view = VaultAutofillListView(
            searchHandler: searchHandler,
            store: store,
            timeProvider: services.timeProvider
        )
        let viewController = UIHostingController(rootView: view)
        let searchController = UISearchController()
        searchController.searchBar.placeholder = Localizations.search
        searchController.searchResultsUpdater = searchHandler

        stackNavigator?.push(
            viewController,
            navigationTitle: group.navigationTitle,
            searchController: searchController
        )
    }

    /// Shows the vault group screen.
    ///
    /// - Parameters:
    ///   - group: The group of items to display.
    ///   - filter: The filter to apply to the view.
    ///
    private func showGroup(_ group: VaultListGroup, filter: VaultFilterType) {
        let processor = VaultGroupProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: VaultGroupState(
                group: group,
                iconBaseURL: services.environmentService.iconsURL,
                vaultFilterType: filter
            ),
            vaultItemMoreOptionsHelper: DefaultVaultItemMoreOptionsHelper(
                coordinator: asAnyCoordinator(),
                services: services
            )
        )
        let store = Store(processor: processor)
        let searchHandler = VaultGroupSearchHandler(store: store)
        let view = VaultGroupView(
            searchHandler: searchHandler,
            store: store,
            timeProvider: services.timeProvider
        )
        let viewController = UIHostingController(rootView: view)
        let searchController = UISearchController()
        searchController.searchBar.placeholder = Localizations.search
        searchController.searchResultsUpdater = searchHandler

        stackNavigator?.push(
            viewController,
            navigationTitle: group.navigationTitle,
            searchController: searchController
        )
    }

    /// Shows the Credential Exchange import route (not in a tab). This is used when another app
    /// exporting credentials with Credential Exchange protocol chooses our app as a provider to import credentials.
    ///
    /// - Parameter route: The `ImportCXFRoute` to show.
    ///
    private func showImportCXF(route: ImportCXFRoute) {
        let navigationController = UINavigationController()
        let coordinator = module.makeImportCXFCoordinator(
            stackNavigator: navigationController
        )
        coordinator.start()
        coordinator.navigate(to: route)
        stackNavigator?.present(navigationController)
    }

    /// Shows the import login items screen.
    ///
    private func showImportLogins() {
        let navigationController = UINavigationController()
        navigationController.modalPresentationStyle = .fullScreen
        let coordinator = module.makeImportLoginsCoordinator(
            delegate: self,
            stackNavigator: navigationController
        )
        coordinator.start()
        coordinator.navigate(to: .importLogins(.vault))
        stackNavigator?.present(navigationController)
    }

    /// Shows the vault list screen.
    ///
    private func showList() {
        let processor = VaultListProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: VaultListState(
                iconBaseURL: services.environmentService.iconsURL
            ),
            twoFactorNoticeHelper: DefaultTwoFactorNoticeHelper(
                coordinator: asAnyCoordinator(),
                services: services
            ),
            vaultItemMoreOptionsHelper: DefaultVaultItemMoreOptionsHelper(
                coordinator: asAnyCoordinator(),
                services: services
            )
        )
        let store = Store(processor: processor)
        let windowScene = stackNavigator?.rootViewController?.view.window?.windowScene
        let view = VaultListView(
            store: store,
            timeProvider: services.timeProvider,
            windowScene: windowScene
        )
        if windowScene == nil {
            services.errorReporter.log(error: WindowSceneError.nullWindowScene)
        }
        stackNavigator?.replace(view, animated: false)
    }

    /// Shows the notice that the user does not have two-factor set up.
    ///
    /// - Parameters:
    ///   - allowDelay: Whether or not the user can temporarily dismiss the notice.
    ///   - emailAddress: The email address of the user.
    private func showTwoFactorNotice(allowDelay: Bool, emailAddress: String) {
        let navigationController = UINavigationController()

        let coordinator = module.makeTwoFactorNoticeCoordinator(stackNavigator: navigationController)
        coordinator.start()
        coordinator.navigate(
            to: .emailAccess(allowDelay: allowDelay, emailAddress: emailAddress),
            context: delegate
        )

        stackNavigator?.present(navigationController, overFullscreen: true)
    }

    /// Presents a vault item coordinator, which will navigate to the provided route.
    ///
    /// - Parameter route: The route to navigate to in the coordinator.
    ///
    private func showVaultItem(route: VaultItemRoute, delegate: CipherItemOperationDelegate?) {
        let navigationController = UINavigationController()
        let coordinator = module.makeVaultItemCoordinator(stackNavigator: navigationController)
        coordinator.start()
        coordinator.navigate(to: route, context: delegate)

        stackNavigator?.present(navigationController)
    }

    /// Shows the vault item selection screen.
    ///
    /// - Parameter totpKeyModel: The parsed TOTP data to search for matching ciphers.
    ///
    func showVaultItemSelection(totpKeyModel: TOTPKeyModel) {
        let userVerificationHelper = DefaultUserVerificationHelper(
            authRepository: services.authRepository,
            errorReporter: services.errorReporter,
            localAuthService: services.localAuthService
        )
        userVerificationHelper.userVerificationDelegate = self

        let processor = VaultItemSelectionProcessor(
            coordinator: asAnyCoordinator(),
            services: services,
            state: VaultItemSelectionState(
                iconBaseURL: services.environmentService.iconsURL,
                totpKeyModel: totpKeyModel
            ),
            userVerificationHelper: userVerificationHelper,
            vaultItemMoreOptionsHelper: DefaultVaultItemMoreOptionsHelper(
                coordinator: asAnyCoordinator(),
                services: services
            )
        )

        let view = VaultItemSelectionView(store: Store(processor: processor))
        let viewController = UIHostingController(rootView: view)
        stackNavigator?.present(UINavigationController(rootViewController: viewController))
    }
}

// MARK: - ImportLoginsCoordinatorDelegate

extension VaultCoordinator: ImportLoginsCoordinatorDelegate {
    func didCompleteLoginsImport() {
        stackNavigator?.dismiss {
            self.showToast(
                Localizations.loginsImported,
                subtitle: Localizations.rememberToDeleteYourImportedPasswordFileFromYourComputer,
                additionalBottomPadding: FloatingActionButton.bottomOffsetPadding
            )
        }
    }
}

// MARK: - UserVerificationDelegate

extension VaultCoordinator: UserVerificationDelegate {} // swiftlint:disable:this file_length
