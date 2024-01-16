import BitwardenSdk
import SwiftUI

// MARK: - VaultListProcessor

/// The processor used to manage state and handle actions for the vault list screen.
///
final class VaultListProcessor: StateProcessor<VaultListState, VaultListAction, VaultListEffect> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter
        & HasPasteboardService
        & HasStateService
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` that handles navigation.
    private let coordinator: AnyCoordinator<VaultRoute>

    /// The services used by this processor.
    private let services: Services

    // MARK: Initialization

    /// Creates a new `VaultListProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` that handles navigation.
    ///   - services: The services used by this processor.
    ///   - state: The initial state of the processor.
    ///
    init(
        coordinator: AnyCoordinator<VaultRoute>,
        services: Services,
        state: VaultListState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultListEffect) async {
        switch effect {
        case .appeared:
            await refreshVault(isManualRefresh: false)
        case let .profileSwitcher(profileEffect):
            switch profileEffect {
            case let .rowAppeared(rowType):
                guard state.profileSwitcherState.shouldSetAccessibilityFocus(for: rowType) == true else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.state.profileSwitcherState.hasSetAccessibilityFocus = true
                }
            }
        case .refreshAccountProfiles:
            await refreshProfileState()
        case .refreshVault:
            await refreshVault(isManualRefresh: true)
        case let .search(text):
            state.searchResults = await searchVault(for: text)
        case .streamOrganizations:
            await streamOrganizations()
        case .streamShowWebIcons:
            for await value in await services.stateService.showWebIconsPublisher() {
                state.showWebIcons = value
            }
        case .streamVaultList:
            await streamVaultList()
        }
    }

    override func receive(_ action: VaultListAction) {
        switch action {
        case .addItemPressed:
            setProfileSwitcher(visible: false)
            coordinator.navigate(to: .addItem())
        case .clearURL:
            state.url = nil
        case .copyTOTPCode:
            break
        case let .itemPressed(item):
            switch item.itemType {
            case .cipher:
                coordinator.navigate(to: .viewItem(id: item.id), context: self)
            case let .group(group, _):
                coordinator.navigate(to: .group(group, filter: state.vaultFilterType))
            case let .totp(_, model):
                coordinator.navigate(to: .viewItem(id: model.id))
            }
        case let .profileSwitcherAction(profileAction):
            switch profileAction {
            case let .accountPressed(account):
                didTapProfileSwitcherItem(account)
            case .addAccountPressed:
                addAccount()
            case .backgroundPressed:
                setProfileSwitcher(visible: false)
            case let .requestedProfileSwitcher(visible: isVisible):
                state.profileSwitcherState.isVisible = isVisible
            case let .scrollOffsetChanged(newOffset):
                state.profileSwitcherState.scrollOffset = newOffset
            }
        case let .morePressed(item):
            showMoreOptionsAlert(for: item)
        case let .searchStateChanged(isSearching: isSearching):
            guard isSearching else { return }
            state.profileSwitcherState.isVisible = !isSearching
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .searchVaultFilterChanged(newValue):
            state.searchVaultFilterType = newValue
        case let .toastShown(newValue):
            state.toast = newValue
        case .totpCodeExpired:
            // No-op: TOTP codes aren't shown on the list view and can't be copied.
            break
        case let .vaultFilterChanged(newValue):
            state.vaultFilterType = newValue
        }
    }

    // MARK: - Private Methods

    /// Navigates to login to initiate the add account flow.
    private func addAccount() {
        coordinator.navigate(to: .addAccount)
    }

    /// Handles a tap of an account in the profile switcher.
    ///
    /// - Parameter selectedAccount: The `ProfileSwitcherItem` selected by the user.
    ///
    private func didTapProfileSwitcherItem(_ selectedAccount: ProfileSwitcherItem) {
        defer { setProfileSwitcher(visible: false) }
        guard state.profileSwitcherState.activeAccountId != selectedAccount.userId else { return }
        coordinator.navigate(
            to: .switchAccount(userId: selectedAccount.userId)
        )
    }

    /// Configures a profile switcher state with the current account and alternates.
    ///
    /// - Returns: A current ProfileSwitcherState, if available.
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
                isVisible: state.profileSwitcherState.isVisible
            )
        } catch {
            services.errorReporter.log(error: error)
            state.profileSwitcherState = .empty()
        }
    }

    /// Refreshes the vault's contents.
    ///
    /// - Parameter isManualRefresh: Whether the sync is being performed as a manual refresh.
    ///
    private func refreshVault(isManualRefresh: Bool) async {
        do {
            try await services.vaultRepository.fetchSync(isManualRefresh: isManualRefresh)
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }

    /// Searches the vault using the provided string, and returns any matching results.
    ///
    /// - Parameter searchText: The string to use when searching the vault.
    /// - Returns: An array of `VaultListItem`s. If no results can be found, an empty array will be returned.
    ///
    private func searchVault(for searchText: String) async -> [VaultListItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        do {
            let result = try await services.vaultRepository.searchCipherPublisher(
                searchText: searchText,
                filterType: state.searchVaultFilterType
            )
            for try await ciphers in result {
                return ciphers
            }
        } catch {
            services.errorReporter.log(error: error)
        }
        return []
    }

    /// Sets the visibility of the profiles view and updates accessibility focus
    /// - Parameter visible: the intended visibility of the view
    private func setProfileSwitcher(visible: Bool) {
        if !visible {
            state.profileSwitcherState.hasSetAccessibilityFocus = false
        }
        state.profileSwitcherState.isVisible = visible
    }

    /// Streams the user's organizations.
    private func streamOrganizations() async {
        do {
            for try await organizations in try await services.vaultRepository.organizationsPublisher() {
                state.organizations = organizations
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Streams the user's vault list.
    private func streamVaultList() async {
        do {
            for try await value in try await services.vaultRepository
                .vaultListPublisher(filter: state.vaultFilterType) {
                state.loadingState = .data(value)
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Show the more options alert for the selected item.
    ///
    /// - Parameter item: The selected item to show the options for.
    ///
    private func showMoreOptionsAlert(for item: VaultListItem) {
        // Only ciphers have more options.
        guard case let .cipher(cipherView) = item.itemType else { return }

        coordinator.showAlert(.moreOptions(
            cipherView: cipherView,
            id: item.id,
            showEdit: true,
            action: handleMoreOptionsAction
        ))
    }

    /// Handle the result of the selected option on the More Options alert..
    ///
    /// - Parameter action: The selected action.
    ///
    private func handleMoreOptionsAction(_ action: MoreOptionsAction) {
        switch action {
        case let .copy(toast, value, requiresMasterPasswordReprompt):
            if requiresMasterPasswordReprompt {
                presentMasterPasswordRepromptAlert {
                    self.services.pasteboardService.copy(value)
                    self.state.toast = Toast(text: Localizations.valueHasBeenCopied(toast))
                }
            } else {
                services.pasteboardService.copy(value)
                state.toast = Toast(text: Localizations.valueHasBeenCopied(toast))
            }
        case let .edit(cipherView):
            coordinator.navigate(to: .editItem(cipherView), context: self)
        case let .launch(url):
            state.url = url.sanitized
        case let .view(id):
            coordinator.navigate(to: .viewItem(id: id))
        }
    }

    /// Presents the master password reprompt alert and calls the completion handler when the user's
    /// master password has been confirmed.
    ///
    /// - Parameter completion: A completion handler that is called when the user's master password
    ///     has been confirmed.
    ///
    private func presentMasterPasswordRepromptAlert(completion: @escaping () -> Void) {
        let alert = Alert.masterPasswordPrompt { [weak self] password in
            guard let self else { return }

            do {
                let isValid = try await services.vaultRepository.validatePassword(password)
                guard isValid else {
                    coordinator.showAlert(.defaultAlert(title: Localizations.invalidMasterPassword))
                    return
                }
                completion()
            } catch {
                services.errorReporter.log(error: error)
            }
        }
        coordinator.showAlert(alert)
    }
}

// MARK: - CipherItemOperationDelegate

extension VaultListProcessor: CipherItemOperationDelegate {
    func itemDeleted() {
        state.toast = Toast(text: Localizations.itemSoftDeleted)
    }
}

// MARK: - MoreOptionsAction

/// The actions available from the More Options alert.
enum MoreOptionsAction {
    /// Copy the `value` and show a toast with the `toast` string.
    case copy(toast: String, value: String, requiresMasterPasswordReprompt: Bool)

    /// Navigate to the view to edit the `cipherView`.
    case edit(cipherView: CipherView)

    /// Launch the `url` in the device's browser.
    case launch(url: URL)

    /// Navigate to view the item with the given `id`.
    case view(id: String)
}
