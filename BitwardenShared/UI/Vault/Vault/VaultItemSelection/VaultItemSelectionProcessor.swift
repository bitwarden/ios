// MARK: - VaultItemSelectionProcessor

/// The processor used to manage state and handle actions for the vault item selection screen.
///
class VaultItemSelectionProcessor: StateProcessor<
    VaultItemSelectionState,
    VaultItemSelectionAction,
    VaultItemSelectionEffect
> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter
        & HasPasteboardService
        & HasStateService
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private var coordinator: AnyCoordinator<VaultRoute, AuthAction>

    /// The services used by this processor.
    private var services: Services

    // MARK: Initialization

    /// Initialize a `VaultItemSelectionProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The coordinator that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute, AuthAction>,
        services: Services,
        state: VaultItemSelectionState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultItemSelectionEffect) async {
        switch effect {
        case .loadData:
            await refreshProfileState()
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
        case .vaultListItemTapped:
            // TODO: BIT-2349 Allow users to add authenticator key to existing items
            break
        }
    }

    override func receive(_ action: VaultItemSelectionAction) {
        switch action {
        case .addTapped:
            state.profileSwitcherState.setIsVisible(false)
            coordinator.navigate(
                to: .addItem(
                    allowTypeSelection: false,
                    group: .login,
                    newCipherOptions: NewCipherOptions(
                        name: state.ciphersMatchingName,
                        totpKey: state.otpAuthModel.uri
                    )
                )
            )
        case .cancelTapped:
            coordinator.navigate(to: .dismiss)
        case let .profileSwitcher(action):
            handle(action)
        case let .searchStateChanged(isSearching: isSearching):
            guard isSearching else { return }
            state.searchText = ""
            state.searchResults = []
            state.showNoResults = false
            state.profileSwitcherState.isVisible = false
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }

    // MARK: Private Methods

    /// Handles receiving a `ProfileSwitcherAction`.
    ///
    /// - Parameter action: The `ProfileSwitcherAction` to handle.
    ///
    private func handle(_ profileSwitcherAction: ProfileSwitcherAction) {
        switch profileSwitcherAction {
        case let .accessibility(accessibilityAction):
            switch accessibilityAction {
            case .logout:
                // No-op: account logout not supported in the extension.
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

    /// Searches the list of ciphers for those matching the search term.
    ///
    private func searchVault(for searchText: String) async {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            state.searchResults = []
            state.showNoResults = false
            return
        }
        do {
            let searchPublisher = try await services.vaultRepository.searchVaultListPublisher(
                searchText: searchText,
                group: .login,
                filterType: .allVaults
            )
            for try await items in searchPublisher {
                state.searchResults = items
                state.showNoResults = items.isEmpty
            }
        } catch {
            state.searchResults = []
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// Streams the list of vault items.
    ///
    private func streamVaultItems() async {
        guard let searchName = state.ciphersMatchingName else { return }
        do {
            for try await items in try await services.vaultRepository.searchVaultListPublisher(
                searchText: searchName,
                group: .login,
                filterType: .allVaults
            ) {
                guard !items.isEmpty else {
                    state.vaultListSections = []
                    continue
                }

                state.vaultListSections = [
                    VaultListSection(
                        id: Localizations.matchingItems,
                        items: items,
                        name: Localizations.matchingItems
                    ),
                ]
            }
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
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

    var toast: Toast? {
        get {
            state.toast
        }
        set {
            state.toast = newValue
        }
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
}
