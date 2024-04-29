import BitwardenSdk
import Foundation

// swiftlint:disable file_length

// MARK: - VaultGroupProcessor

/// A `Processor` that can process `VaultGroupAction`s and `VaultGroupEffect`s.
final class VaultGroupProcessor: StateProcessor<// swiftlint:disable:this type_body_length
    VaultGroupState,
    VaultGroupAction,
    VaultGroupEffect
> {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter
        & HasPasteboardService
        & HasPolicyService
        & HasStateService
        & HasTimeProvider
        & HasVaultRepository

    // MARK: Delegates

    // MARK: Private Properties

    /// The `Coordinator` for this processor.
    private var coordinator: any Coordinator<VaultRoute, AuthAction>

    /// The services for this processor.
    private var services: Services

    /// An object to manage TOTP code expirations and batch refresh calls for the group.
    private var groupTotpExpirationManager: TOTPExpirationManager?

    /// An object to manage TOTP code expirations and batch refresh calls for search results.
    private var searchTotpExpirationManager: TOTPExpirationManager?

    // MARK: Initialization

    /// Creates a new `VaultGroupProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` for this processor.
    ///   - services: The services for this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: any Coordinator<VaultRoute, AuthAction>,
        services: Services,
        state: VaultGroupState
    ) {
        self.coordinator = coordinator
        self.services = services

        super.init(state: state)
        groupTotpExpirationManager = .init(
            timeProvider: services.timeProvider,
            onExpiration: { [weak self] expiredItems in
                guard let self else { return }
                Task {
                    await self.refreshTOTPCodes(for: expiredItems)
                }
            }
        )
        searchTotpExpirationManager = .init(
            timeProvider: services.timeProvider,
            onExpiration: { [weak self] expiredSearchItems in
                guard let self else { return }
                Task {
                    await self.refreshTOTPCodes(searchItems: expiredSearchItems)
                }
            }
        )
    }

    deinit {
        groupTotpExpirationManager?.cleanup()
        groupTotpExpirationManager = nil
    }

    // MARK: Methods

    override func perform(_ effect: VaultGroupEffect) async {
        switch effect {
        case .appeared:
            await checkPersonalOwnershipPolicy()
            await streamVaultList()
        case let .morePressed(item):
            await showMoreOptionsAlert(for: item)
        case .refresh:
            await refreshVaultGroup()
        case let .search(text):
            let results = await searchGroup(for: text)
            state.searchResults = results
            searchTotpExpirationManager?.configureTOTPRefreshScheduling(for: results)
        case .streamOrganizations:
            await streamOrganizations()
        case .streamShowWebIcons:
            for await value in await services.stateService.showWebIconsPublisher().values {
                state.showWebIcons = value
            }
        }
    }

    override func receive(_ action: VaultGroupAction) {
        switch action {
        case .addItemPressed:
            coordinator.navigate(to: .addItem(group: state.group))
        case .clearURL:
            state.url = nil
        case let .copyTOTPCode(code):
            services.pasteboardService.copy(code)
            state.toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.verificationCode))
        case let .itemPressed(item):
            switch item.itemType {
            case .cipher:
                coordinator.navigate(to: .viewItem(id: item.id), context: self)
            case let .group(group, _):
                coordinator.navigate(to: .group(group, filter: state.vaultFilterType))
            case let .totp(_, model):
                coordinator.navigate(to: .viewItem(id: model.id))
            }
        case let .searchStateChanged(isSearching):
            if !isSearching {
                state.searchText = ""
                state.searchResults = []
                searchTotpExpirationManager?.configureTOTPRefreshScheduling(for: [])
            }
            state.isSearching = isSearching
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .searchVaultFilterChanged(newValue):
            state.searchVaultFilterType = newValue
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }

    // MARK: Private Methods

    /// Checks if the personal ownership policy is enabled.
    ///
    private func checkPersonalOwnershipPolicy() async {
        let isPersonalOwnershipDisabled = await services.policyService.policyAppliesToUser(.personalOwnership)
        state.isPersonalOwnershipDisabled = isPersonalOwnershipDisabled
    }

    /// Generates and copies a TOTP code for the cipher's TOTP key.
    ///
    /// - Parameter totpKey: The TOTP key used to generate a TOTP code.
    ///
    private func generateAndCopyTotpCode(totpKey: TOTPKeyModel) async {
        do {
            let response = try await services.vaultRepository.refreshTOTPCode(for: totpKey)
            if let code = response.codeModel?.code {
                services.pasteboardService.copy(code)
                state.toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.verificationCodeTotp))
            } else {
                coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            }
        } catch {
            coordinator.showAlert(.defaultAlert(title: Localizations.anErrorHasOccurred))
            services.errorReporter.log(error: error)
        }
    }

    /// Refreshes the vault group's TOTP Codes.
    ///
    private func refreshTOTPCodes(for items: [VaultListItem]) async {
        guard case let .data(currentSections) = state.loadingState else { return }
        do {
            let refreshedItems = try await services.vaultRepository.refreshTOTPCodes(for: items)
            let updatedSections = currentSections.updated(with: refreshedItems)
            let allItems = updatedSections.flatMap(\.items)
            groupTotpExpirationManager?.configureTOTPRefreshScheduling(for: allItems)
            state.loadingState = .data(updatedSections)
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Refreshes TOTP Codes for the search results.
    ///
    private func refreshTOTPCodes(searchItems: [VaultListItem]) async {
        let currentSearchResults = state.searchResults
        do {
            let refreshedSearchResults = try await services.vaultRepository.refreshTOTPCodes(for: searchItems)
            let allSearchResults = currentSearchResults.updated(with: refreshedSearchResults)
            searchTotpExpirationManager?.configureTOTPRefreshScheduling(for: allSearchResults)
            state.searchResults = allSearchResults
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Refreshes the vault group's contents.
    ///
    private func refreshVaultGroup() async {
        do {
            try await services.vaultRepository.fetchSync(isManualRefresh: true, filter: state.vaultFilterType)
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
    private func searchGroup(for searchText: String) async -> [VaultListItem] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        do {
            let result = try await services.vaultRepository.searchVaultListPublisher(
                searchText: searchText,
                group: state.group,
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

    /// Show the more options alert for the selected item.
    ///
    /// - Parameter item: The selected item to show the options for.
    ///
    private func showMoreOptionsAlert(for item: VaultListItem) async {
        do {
            // Only ciphers have more options.
            guard case let .cipher(cipherView) = item.itemType else { return }

            let hasPremium = await (try? services.vaultRepository.doesActiveAccountHavePremium()) ?? false
            state.hasMasterPassword = try await services.stateService.getUserHasMasterPassword()

            coordinator.showAlert(.moreOptions(
                cipherView: cipherView,
                hasPremium: hasPremium,
                id: item.id,
                showEdit: state.group != .trash,
                action: handleMoreOptionsAction
            ))
        } catch {
            services.errorReporter.log(error: error)
        }
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

    /// Stream the vault list.
    private func streamVaultList() async {
        do {
            for try await vaultList in try await services.vaultRepository.vaultListPublisher(
                group: state.group,
                filter: state.vaultFilterType
            ) {
                groupTotpExpirationManager?.configureTOTPRefreshScheduling(for: vaultList.flatMap(\.items))
                state.loadingState = .data(vaultList)
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Handle the result of the selected option on the More Options alert..
    ///
    /// - Parameter action: The selected action.
    ///
    private func handleMoreOptionsAction(_ action: MoreOptionsAction) async {
        switch action {
        case let .copy(toast, value, requiresMasterPasswordReprompt):
            if requiresMasterPasswordReprompt, state.hasMasterPassword {
                presentMasterPasswordRepromptAlert {
                    self.services.pasteboardService.copy(value)
                    self.state.toast = Toast(text: Localizations.valueHasBeenCopied(toast))
                }
            } else {
                services.pasteboardService.copy(value)
                state.toast = Toast(text: Localizations.valueHasBeenCopied(toast))
            }
        case let .copyTotp(totpKey, requiresMasterPasswordReprompt):
            if requiresMasterPasswordReprompt, state.hasMasterPassword {
                presentMasterPasswordRepromptAlert {
                    await self.generateAndCopyTotpCode(totpKey: totpKey)
                }
            } else {
                await generateAndCopyTotpCode(totpKey: totpKey)
            }
        case let .edit(cipherView):
            if cipherView.reprompt == .password, state.hasMasterPassword {
                presentMasterPasswordRepromptAlert {
                    self.coordinator.navigate(to: .editItem(cipherView), context: self)
                }
            } else {
                coordinator.navigate(to: .editItem(cipherView), context: self)
            }
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
    private func presentMasterPasswordRepromptAlert(completion: @escaping () async -> Void) {
        let alert = Alert.masterPasswordPrompt { [weak self] password in
            guard let self else { return }

            do {
                let isValid = try await services.authRepository.validatePassword(password)
                guard isValid else {
                    coordinator.showAlert(.defaultAlert(title: Localizations.invalidMasterPassword))
                    return
                }
                await completion()
            } catch {
                services.errorReporter.log(error: error)
            }
        }
        coordinator.showAlert(alert)
    }
}

// MARK: - CipherItemOperationDelegate

extension VaultGroupProcessor: CipherItemOperationDelegate {
    func itemDeleted() {
        state.toast = Toast(text: Localizations.itemDeleted)
        Task {
            await perform(.refresh)
        }
    }

    func itemSoftDeleted() {
        state.toast = Toast(text: Localizations.itemSoftDeleted)
        Task {
            await perform(.refresh)
        }
    }

    func itemRestored() {
        state.toast = Toast(text: Localizations.itemRestored)
        Task {
            await perform(.refresh)
        }
    }
}

/// A class to manage TOTP code expirations for the VaultGroupProcessor and batch refresh calls.
///
private class TOTPExpirationManager {
    // MARK: Properties

    /// A closure to call on expiration
    ///
    var onExpiration: (([VaultListItem]) -> Void)?

    // MARK: Private Properties

    /// All items managed by the object, grouped by TOTP period.
    ///
    private(set) var itemsByInterval = [UInt32: [VaultListItem]]()

    /// A model to provide time to calculate the countdown.
    ///
    private var timeProvider: any TimeProvider

    /// A timer that triggers `checkForExpirations` to manage code expirations.
    ///
    private var updateTimer: Timer?

    /// Initializes a new countdown timer
    ///
    /// - Parameters
    ///   - timeProvider: A protocol providing the present time as a `Date`.
    ///         Used to calculate time remaining for a present TOTP code.
    ///   - onExpiration: A closure to call on code expiration for a list of vault items.
    ///
    init(
        timeProvider: any TimeProvider,
        onExpiration: (([VaultListItem]) -> Void)?
    ) {
        self.timeProvider = timeProvider
        self.onExpiration = onExpiration
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: 0.25,
            repeats: true,
            block: { _ in
                self.checkForExpirations()
            }
        )
    }

    /// Clear out any timers tracking TOTP code expiration
    deinit {
        cleanup()
    }

    // MARK: Methods

    /// Configures TOTP code refresh scheduling
    ///
    /// - Parameter items: The vault list items that may require code expiration tracking.
    ///
    func configureTOTPRefreshScheduling(for items: [VaultListItem]) {
        var newItemsByInterval = [UInt32: [VaultListItem]]()
        items.forEach { item in
            guard case let .totp(_, model) = item.itemType else { return }
            newItemsByInterval[model.totpCode.period, default: []].append(item)
        }
        itemsByInterval = newItemsByInterval
    }

    /// A function to remove any outstanding timers
    ///
    func cleanup() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func checkForExpirations() {
        var expired = [VaultListItem]()
        var notExpired = [UInt32: [VaultListItem]]()
        itemsByInterval.forEach { period, items in
            let sortedItems: [Bool: [VaultListItem]] = TOTPExpirationCalculator.listItemsByExpiration(
                items,
                timeProvider: timeProvider
            )
            expired.append(contentsOf: sortedItems[true] ?? [])
            notExpired[period] = sortedItems[false]
        }
        itemsByInterval = notExpired
        guard !expired.isEmpty else { return }
        onExpiration?(expired)
    }
}
