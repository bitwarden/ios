import BitwardenSdk
import Foundation

// MARK: - VaultGroupProcessor

/// A `Processor` that can process `VaultGroupAction`s and `VaultGroupEffect`s.
final class VaultGroupProcessor: StateProcessor<
    VaultGroupState,
    VaultGroupAction,
    VaultGroupEffect
>, HasTOTPCodesSections {
    // MARK: Types

    typealias Services = HasAuthRepository
        & HasErrorReporter
        & HasEventService
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

    /// The helper to handle the more options menu for a vault item.
    private let vaultItemMoreOptionsHelper: VaultItemMoreOptionsHelper

    var vaultRepository: VaultRepository {
        services.vaultRepository
    }

    // MARK: Initialization

    /// Creates a new `VaultGroupProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` for this processor.
    ///   - services: The services for this processor.
    ///   - state: The initial state of this processor.
    ///   - vaultItemMoreOptionsHelper: The helper to handle the more options menu for a vault item.
    ///
    init(
        coordinator: any Coordinator<VaultRoute, AuthAction>,
        services: Services,
        state: VaultGroupState,
        vaultItemMoreOptionsHelper: VaultItemMoreOptionsHelper
    ) {
        self.coordinator = coordinator
        self.services = services
        self.vaultItemMoreOptionsHelper = vaultItemMoreOptionsHelper

        super.init(state: state)
        groupTotpExpirationManager = DefaultTOTPExpirationManager(
            timeProvider: services.timeProvider,
            onExpiration: { [weak self] expiredItems in
                guard let self else { return }
                Task {
                    await self.refreshTOTPCodes(for: expiredItems)
                }
            }
        )
        searchTotpExpirationManager = DefaultTOTPExpirationManager(
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
            await vaultItemMoreOptionsHelper.showMoreOptionsAlert(
                for: item,
                handleDisplayToast: { [weak self] toast in
                    self?.state.toast = toast
                },
                handleOpenURL: { [weak self] url in
                    self?.state.url = url
                }
            )
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
            state.toast = Toast(title: Localizations.valueHasBeenCopied(Localizations.verificationCode))
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
        state.canShowVaultFilter = await services.vaultRepository.canShowVaultFilter()
    }

    /// Refreshes the vault group's TOTP Codes.
    ///
    private func refreshTOTPCodes(for items: [VaultListItem]) async {
        guard case let .data(currentSections) = state.loadingState else { return }
        do {
            let updatedSections = try await refreshTOTPCodes(
                for: items,
                in: currentSections,
                using: groupTotpExpirationManager
            )
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
            let updatedSections = try await refreshTOTPCodes(
                for: searchItems,
                in: [
                    VaultListSection(id: "", items: currentSearchResults, name: ""),
                ],
                using: searchTotpExpirationManager
            )
            state.searchResults = updatedSections[0].items
        } catch {
            services.errorReporter.log(error: error)
        }
    }

    /// Refreshes the vault group's contents.
    ///
    private func refreshVaultGroup() async {
        do {
            try await services.vaultRepository.fetchSync(forceSync: true, filter: state.vaultFilterType)
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
                filter: VaultListFilter(filterType: state.searchVaultFilterType)
            )
            for try await ciphers in result {
                return ciphers
            }
        } catch {
            services.errorReporter.log(error: error)
        }
        return []
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
                filter: VaultListFilter(filterType: state.vaultFilterType)
            ) {
                groupTotpExpirationManager?.configureTOTPRefreshScheduling(for: vaultList.flatMap(\.items))
                state.loadingState = .data(vaultList)
            }
        } catch {
            services.errorReporter.log(error: error)
        }
    }
}

// MARK: - CipherItemOperationDelegate

extension VaultGroupProcessor: CipherItemOperationDelegate {
    func itemDeleted() {
        state.toast = Toast(title: Localizations.itemDeleted)
        Task {
            await perform(.refresh)
        }
    }

    func itemSoftDeleted() {
        state.toast = Toast(title: Localizations.itemSoftDeleted)
        Task {
            await perform(.refresh)
        }
    }

    func itemRestored() {
        state.toast = Toast(title: Localizations.itemRestored)
        Task {
            await perform(.refresh)
        }
    }
}
