// MARK: - VaultAutofillListProcessor

/// The processor used to manage state and handle actions for the autofill list screen.
///
class VaultAutofillListProcessor: StateProcessor<
    VaultAutofillListState,
    VaultAutofillListAction,
    VaultAutofillListEffect
> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter
        & HasPasteboardService
        & HasVaultRepository

    // MARK: Private Properties

    /// A delegate used to communicate with the app extension.
    private weak var appExtensionDelegate: AppExtensionDelegate?

    /// A helper that handles autofill for a selected cipher.
    private let autofillHelper: AutofillHelper

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultRoute>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Initialize a `VaultAutofillListProcessor`.
    ///
    /// - Parameters:
    ///   - appExtensionDelegate: A delegate used to communicate with the app extension.
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        appExtensionDelegate: AppExtensionDelegate?,
        coordinator: AnyCoordinator<VaultRoute>,
        services: Services,
        state: VaultAutofillListState
    ) {
        self.appExtensionDelegate = appExtensionDelegate
        autofillHelper = AutofillHelper(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator,
            services: services
        )
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultAutofillListEffect) async {
        switch effect {
        case let .cipherTapped(cipher):
            await autofillHelper.handleCipherForAutofill(cipherView: cipher) { [weak self] toastText in
                self?.state.toast = Toast(text: toastText)
            }
        case .loadData:
            await refreshProfileState()
        case let .search(text):
            await searchVault(for: text)
        case .streamAutofillItems:
            await streamAutofillItems()
        }
    }

    override func receive(_ action: VaultAutofillListAction) {
        switch action {
        case .addTapped:
            state.profileSwitcherState.setIsVisible(false)
            coordinator.navigate(
                to: .addItem(
                    allowTypeSelection: false,
                    group: .login,
                    uri: appExtensionDelegate?.uri
                )
            )
        case .cancelTapped:
            appExtensionDelegate?.didCancel()
        case let .profileSwitcherAction(action):
            handleProfileSwitcherAction(action)
        case let .searchStateChanged(isSearching: isSearching):
            guard isSearching else { return }
            state.searchText = ""
            state.ciphersForSearch = []
            state.showNoResults = false
            state.profileSwitcherState.isVisible = !isSearching
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }

    // MARK: Private Methods

    /// Handles a tap of an account in the profile switcher.
    ///
    /// - Parameter selectedAccount: The `ProfileSwitcherItem` selected by the user.
    ///
    private func didTapProfileSwitcherItem(_ selectedAccount: ProfileSwitcherItem) {
        defer { state.profileSwitcherState.setIsVisible(false) }
        guard state.profileSwitcherState.activeAccountId != selectedAccount.userId else { return }
        coordinator.navigate(
            to: .switchAccount(userId: selectedAccount.userId)
        )
    }

    /// Handles receiving a `ProfileSwitcherAction`.
    ///
    /// - Parameter action: The `ProfileSwitcherAction` to handle.
    ///
    private func handleProfileSwitcherAction(_ action: ProfileSwitcherAction) {
        switch action {
        case .accountLongPressed:
            // No-op: account long-press not supported in the extension.
            break
        case let .accountPressed(account):
            didTapProfileSwitcherItem(account)
        case .addAccountPressed:
            // No-op: add account not supported in the extension.
            break
        case .backgroundPressed:
            state.profileSwitcherState.setIsVisible(false)
        case let .requestedProfileSwitcher(visible: isVisible):
            state.profileSwitcherState.isVisible = isVisible
        case let .scrollOffsetChanged(newOffset):
            state.profileSwitcherState.scrollOffset = newOffset
        }
    }

    /// Configures a profile switcher state with the current account and alternates.
    ///
    private func refreshProfileState() async {
        var accounts = [ProfileSwitcherItem]()
        var activeAccount: ProfileSwitcherItem?
        do {
            accounts = try await services.authRepository.getAccounts()
            activeAccount = try? await services.authRepository.getActiveAccount()

            state.profileSwitcherState = ProfileSwitcherState(
                accounts: accounts,
                activeAccountId: activeAccount?.userId,
                isVisible: state.profileSwitcherState.isVisible,
                shouldAlwaysHideAddAccount: true
            )
        } catch {
            services.errorReporter.log(error: error)
            state.profileSwitcherState = .empty(shouldAlwaysHideAddAccount: true)
        }
    }

    /// Searches the list of ciphers for those matching the search term.
    ///
    private func searchVault(for searchText: String) async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.ciphersForSearch = []
            state.showNoResults = false
            return
        }
        do {
            let searchResult = try await services.vaultRepository.searchCipherAutofillPublisher(
                searchText: searchText,
                filterType: .allVaults
            )
            for try await ciphers in searchResult {
                state.ciphersForSearch = ciphers
                state.showNoResults = ciphers.isEmpty
            }
        } catch {
            state.ciphersForSearch = []
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// Streams the list of autofill items.
    ///
    private func streamAutofillItems() async {
        do {
            for try await ciphers in try await services.vaultRepository.ciphersAutofillPublisher(
                uri: appExtensionDelegate?.uri
            ) {
                state.ciphersForAutofill = ciphers
            }
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }
}
