import BitwardenSdk
import Foundation

// MARK: - VaultGroupProcessor

/// A `Processor` that can process `VaultGroupAction`s and `VaultGroupEffect`s.
final class VaultGroupProcessor: StateProcessor<VaultGroupState, VaultGroupAction, VaultGroupEffect> {
    // MARK: Types

    typealias Services = HasErrorReporter
        & HasPasteboardService
        & HasVaultRepository

    // MARK: Private Properties

    /// The `Coordinator` for this processor.
    private var coordinator: any Coordinator<VaultRoute>

    /// The services for this processor.
    private var services: Services

    // MARK: Initialization

    /// Creates a new `VaultGroupProcessor`.
    ///
    /// - Parameters:
    ///   - coordinator: The `Coordinator` for this processor.
    ///   - services: The services for this processor.
    ///   - state: The initial state of this processor.
    ///
    init(
        coordinator: any Coordinator<VaultRoute>,
        services: Services,
        state: VaultGroupState
    ) {
        self.coordinator = coordinator
        self.services = services
        super.init(state: state)
    }

    // MARK: Methods

    override func perform(_ effect: VaultGroupEffect) async {
        switch effect {
        case .appeared:
            for await value in services.vaultRepository.vaultListPublisher(group: state.group) {
                state.loadingState = .data(value)
            }
        case let .morePressed(item):
            await showMoreOptionsAlert(for: item)
        case .refresh:
            await refreshVaultGroup()
        }
    }

    override func receive(_ action: VaultGroupAction) {
        switch action {
        case .addItemPressed:
            coordinator.navigate(to: .addItem(group: state.group))
        case .clearURL:
            state.url = nil
        case let .itemPressed(item):
            switch item.itemType {
            case .cipher:
                coordinator.navigate(to: .viewItem(id: item.id), context: self)
            case let .group(group, _):
                coordinator.navigate(to: .group(group))
            case let .totp(id: id, _, _):
                coordinator.navigate(to: .viewItem(id: id))
            }
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }

    // MARK: Private Methods

    /// Refreshes the vault group's contents.
    ///
    private func refreshVaultGroup() async {
        do {
            try await services.vaultRepository.fetchSync(isManualRefresh: true)
        } catch {
            // TODO: BIT-1034 Add an error alert
            print(error)
        }
    }

    /// Show the more options alert for the selected item.
    ///
    /// - Parameter item: The selected item to show the options for.
    ///
    private func showMoreOptionsAlert(for item: VaultListItem) async {
        // Load the content of the cipher item to determine which values to show in the menu.
        do {
            guard let cipherView = try await services.vaultRepository.fetchCipher(withId: item.id)
            else { return }

            coordinator.showAlert(.moreOptions(
                cipherView: cipherView,
                id: item.id,
                showEdit: state.group != .trash,
                action: handleMoreOptionsAction
            ))
        } catch {
            coordinator.showAlert(.networkResponseError(error))
            services.errorReporter.log(error: error)
        }
    }

    /// Handle the result of the selected option on the More Options alert..
    ///
    /// - Parameter action: The selected action.
    ///
    private func handleMoreOptionsAction(_ action: MoreOptionsAction) {
        switch action {
        case let .copy(toast: toast, value: value):
            services.pasteboardService.copy(value)
            state.toast = Toast(text: Localizations.valueHasBeenCopied(toast))
        case let .edit(cipherView: cipherView):
            coordinator.navigate(to: .editItem(cipher: cipherView))
        case let .launch(url: url):
            state.url = url.sanitized
        case let .view(id: id):
            coordinator.navigate(to: .viewItem(id: id))
        }
    }
}

// MARK: - CipherItemOperationDelegate

extension VaultGroupProcessor: CipherItemOperationDelegate {
    func itemDeleted() {
        state.toast = Toast(text: Localizations.itemSoftDeleted)
    }
}
