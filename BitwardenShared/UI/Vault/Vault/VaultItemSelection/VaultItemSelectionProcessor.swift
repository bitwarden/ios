import BitwardenKit
import BitwardenResources
import Combine
import Foundation

// MARK: - VaultItemSelectionProcessor

/// The processor used to manage state and handle actions for the vault item selection screen.
///
class VaultItemSelectionProcessor: StateProcessor<
    VaultItemSelectionState,
    VaultItemSelectionAction,
    VaultItemSelectionEffect,
> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasBillingRepository
        & HasBillingService
        & HasEnvironmentService
        & HasErrorReporter
        & HasEventService
        & HasPasteboardService
        & HasSearchProcessorMediatorFactory
        & HasStateService
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultRoute, AuthAction>

    /// A cancellable for the premium checkout status subscription.
    private var premiumStatusChangedCancellable: AnyCancellable?

    /// The mediator between processors and search publisher/subscription behavior.
    private let searchProcessorMediator: SearchProcessorMediator

    /// The services used by this processor.
    private var services: Services

    /// The helper to execute user verification flows.
    private let userVerificationHelper: UserVerificationHelper

    /// The helper to handle the more options menu for a vault item.
    private let vaultItemMoreOptionsHelper: VaultItemMoreOptionsHelper

    // MARK: Initialization

    /// Initialize a `VaultItemSelectionProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///   - userVerificationHelper: The helper to execute user verification flows.
    ///   - vaultItemMoreOptionsHelper: The helper to handle the more options menu for a vault item.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute, AuthAction>,
        services: Services,
        state: VaultItemSelectionState,
        userVerificationHelper: UserVerificationHelper,
        vaultItemMoreOptionsHelper: VaultItemMoreOptionsHelper,
    ) {
        self.coordinator = coordinator
        searchProcessorMediator = services.searchProcessorMediatorFactory.make()
        self.services = services
        self.userVerificationHelper = userVerificationHelper
        self.vaultItemMoreOptionsHelper = vaultItemMoreOptionsHelper

        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultItemSelectionEffect) async {
        switch effect {
        case .loadData:
            await refreshProfileState()
        case let .morePressed(item):
            await vaultItemMoreOptionsHelper.showMoreOptionsAlert(
                for: item,
                handleDisplayToast: { [weak self] toast in
                    self?.state.toast = toast
                },
                handleNavigateToPremiumUpgrade: { [weak self] in
                    await self?.navigateToPremiumUpgrade()
                },
                handleOpenURL: { [weak self] url in
                    self?.state.url = url
                },
            )
        case let .profileSwitcher(profileEffect):
            await handle(profileEffect)
        case let .search(text):
            await searchVault(for: text)
        case .streamShowWebIcons:
            for await value in await services.stateService.showWebIconsPublisher().values {
                state.showWebIcons = value
            }
        case .streamVaultItems:
            await streamVaultItems()
        case let .vaultListItemTapped(item):
            await showEditForNewOtpKey(vaultListItem: item)
        }
    }

    override func receive(_ action: VaultItemSelectionAction) {
        switch action {
        case .addTapped:
            state.profileSwitcherState.setIsVisible(false)
            coordinator.navigate(
                to: .addItem(
                    group: .login,
                    newCipherOptions: NewCipherOptions(
                        name: state.ciphersMatchingName,
                        totpKey: state.totpKeyModel.rawAuthenticatorKey,
                    ),
                    type: .login,
                ),
                context: self,
            )
        case .cancelTapped:
            coordinator.navigate(to: .dismiss())
        case .clearURL:
            state.url = nil
        case let .profileSwitcher(action):
            handle(action)
        case let .searchStateChanged(isSearching: isSearching):
            guard isSearching else {
                state.searchText = ""
                state.searchResults = []
                state.showNoResults = false
                searchProcessorMediator.stopSearching()
                return
            }
            searchProcessorMediator.startSearching(mode: nil) { [weak self] data in
                self?.searchResultsReceived(data: data)
            }
            state.profileSwitcherState.isVisible = false
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }

    // MARK: Private Methods

    /// Navigates to the premium upgrade flow. Uses the in-app upgrade path when available;
    /// otherwise opens the web vault upgrade URL as a fallback.
    ///
    private func navigateToPremiumUpgrade() async {
        guard await services.billingRepository.isInAppUpgradeAvailable() else {
            state.url = services.environmentService.upgradeToPremiumURL
            return
        }
        subscribeToPremiumCheckoutStatus()
        coordinator.navigate(to: .premiumUpgrade)
    }

    /// Subscribes to premium checkout status updates. On `.confirmed`, dismisses the upgrade modal.
    /// On `.pending`, shows an upgrade pending alert.
    ///
    private func subscribeToPremiumCheckoutStatus() {
        premiumStatusChangedCancellable = services.billingService
            .premiumCheckoutStatusPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .canceled:
                    break
                case .confirmed:
                    premiumStatusChangedCancellable = nil
                    coordinator.navigate(
                        to: .dismiss(DismissAction { [weak self] in
                            guard let self else { return }
                            coordinator.hideLoadingOverlay()
                        }),
                    )
                case .pending:
                    coordinator.navigate(
                        to: .dismiss(DismissAction { [weak self] in
                            guard let self else { return }
                            coordinator.hideLoadingOverlay()
                            coordinator.showAlert(.upgradePending {
                                await self.services.billingService.premiumStatusChanged()
                            })
                        }),
                    )
                case .syncing:
                    coordinator.navigate(
                        to: .dismiss(DismissAction { [weak self] in
                            guard let self else { return }
                            coordinator.showLoadingOverlay(
                                title: Localizations.confirmingYourUpgrade,
                            )
                        }),
                    )
                }
            }
    }

    /// Handles receiving a `ProfileSwitcherAction`.
    ///
    /// - Parameter action: The `ProfileSwitcherAction` to handle.
    ///
    private func handle(_ profileSwitcherAction: ProfileSwitcherAction) {
        switch profileSwitcherAction {
        case let .accessibility(accessibilityAction):
            switch accessibilityAction {
            case .logout, .remove:
                // No-op: account logout and remove are not supported in this view.
                break
            }
        default:
            handleProfileSwitcherAction(profileSwitcherAction)
        }
    }

    /// Handles receiving a `ProfileSwitcherEffect`.
    ///
    /// - Parameter action: The `ProfileSwitcherEffect` to handle.
    ///
    private func handle(_ profileSwitcherEffect: ProfileSwitcherEffect) async {
        switch profileSwitcherEffect {
        case let .accessibility(accessibilityAction):
            switch accessibilityAction {
            case .lock:
                // No-op: account lock not supported in the extension.
                break
            default:
                await handleProfileSwitcherEffect(profileSwitcherEffect)
            }
        default:
            await handleProfileSwitcherEffect(profileSwitcherEffect)
        }
    }

    /// Function to be called when new search results are received.
    /// - Parameters:
    ///     - data: The new search results data.
    ///
    private func searchResultsReceived(data: VaultListData) {
        let items = data.sections.first?.items ?? []
        state.searchResults = items
        state.showNoResults = items.isEmpty
    }

    /// Searches the list of ciphers for those matching the search term.
    ///
    private func searchVault(for searchText: String) async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.searchResults = []
            state.showNoResults = false
            return
        }

        searchProcessorMediator.updateFilter(
            VaultListFilter(
                filterType: .allVaults,
                group: .login,
                searchText: searchText,
            ),
        )
    }

    /// Shows the edit item screen for the cipher within the specified vault list item with the OTP
    /// key added.
    ///
    /// - Parameter vaultListItem: The vault list item containing a cipher which the user selected
    ///     to add the OTP key to.
    ///
    private func showEditForNewOtpKey(vaultListItem: VaultListItem) async {
        guard case let .cipher(cipher, _) = vaultListItem.itemType,
              cipher.type.isLogin else {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            return
        }

        do {
            if try await services.authRepository.shouldPerformMasterPasswordReprompt(reprompt: cipher.reprompt) {
                guard try await userVerificationHelper.verifyMasterPassword() == .verified else {
                    return
                }
            }

            guard let cipherId = cipher.id,
                  let cipherView = try await services.vaultRepository.fetchCipher(withId: cipherId),
                  let login = cipherView.login else {
                coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
                return
            }

            let updatedCipherView = cipherView.update(login: login.update(totp: state.totpKeyModel.rawAuthenticatorKey))
            coordinator.navigate(to: .editItem(updatedCipherView), context: self)
        } catch UserVerificationError.cancelled {
            // No-op: don't log or alert for cancellation errors.
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// Streams the list of vault items.
    ///
    private func streamVaultItems() async {
        guard let searchName = state.ciphersMatchingName else { return }
        do {
            for try await vaultListData in try await services.vaultRepository.vaultListPublisher(
                filter: VaultListFilter(
                    filterType: .allVaults,
                    group: .login,
                    options: [.isInPickerMode],
                    searchText: searchName,
                ),
            ) {
                state.vaultListSections = vaultListData.sections
            }
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }
}

// MARK: - CipherItemOperationDelegate

extension VaultItemSelectionProcessor: CipherItemOperationDelegate {
    func itemAdded() -> Bool {
        coordinator.navigate(to: .dismiss())
        // Return false to notify the calling processor that the dismissal occurs here.
        return false
    }

    func itemArchived() {
        coordinator.navigate(to: .dismiss())
    }

    func itemUnarchived() {
        coordinator.navigate(to: .dismiss())
    }

    func itemUpdated() -> Bool {
        coordinator.navigate(to: .dismiss())
        // Return false to notify the calling processor that the dismissal occurs here.
        return false
    }
}

// MARK: - ProfileSwitcherHandler

extension VaultItemSelectionProcessor: ProfileSwitcherHandler {
    var allowLockAndLogout: Bool {
        false
    }

    var profileServices: ProfileServices {
        services
    }

    var profileSwitcherState: ProfileSwitcherState {
        get {
            state.profileSwitcherState
        }
        set {
            state.profileSwitcherState = newValue
        }
    }

    var shouldHideAddAccount: Bool {
        true
    }

    var switchAccountAuthCompletionRoute: AppRoute? {
        .tab(.vault(.vaultItemSelection(state.totpKeyModel)))
    }

    var toast: Toast? {
        get {
            state.toast
        }
        set {
            state.toast = newValue
        }
    }

    func dismissProfileSwitcher() {
        coordinator.navigate(to: .dismiss())
    }

    func handleAuthEvent(_ authEvent: AuthEvent) async {
        guard case let .action(authAction) = authEvent else { return }
        await coordinator.handleEvent(authAction)
    }

    func showAddAccount() {
        // No-Op for the VaultItemSelectionProcessor.
    }

    func showAlert(_ alert: Alert) {
        // No-Op for the VaultItemSelectionProcessor.
    }

    func showProfileSwitcher() {
        coordinator.navigate(to: .viewProfileSwitcher, context: self)
    }
} // swiftlint:disable:this file_length
