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
        case .refresh:
            await refreshVaultGroup()
        }
    }

    override func receive(_ action: VaultGroupAction) {
        switch action {
        case .addItemPressed:
            coordinator.navigate(to: .addItem(group: state.group))
        case let .copyTOTPCode(code):
            services.pasteboardService.copy(code)
            state.toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.verificationCode))
        case let .itemPressed(item):
            switch item.itemType {
            case .cipher:
                coordinator.navigate(to: .viewItem(id: item.id), context: self)
            case let .group(group, _):
                coordinator.navigate(to: .group(group))
            case let .totp(model):
                coordinator.navigate(to: .viewItem(id: model.id))
            }
        case let .morePressed(item):
            // TODO: BIT-375 Show the more menu
            print("more: \(item.id)")
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .toastShown(newValue):
            state.toast = newValue
        case .totpCodeExpired:
            Task { await refreshTOTPCodes() }
        }
    }

    // MARK: Private Methods

    /// Refreshes the vault group's TOTP Codes.
    ///
    private func refreshTOTPCodes() async {
        guard case let .data(items) = state.loadingState else { return }
        do {
            let refreshedItems = try await services.vaultRepository.refreshTOTPCodes(for: items)
            state.loadingState = .data(refreshedItems)
        } catch {
            services.errorReporter.log(error: error)
        }
    }

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
}

// MARK: - CipherItemOperationDelegate

extension VaultGroupProcessor: CipherItemOperationDelegate {
    func itemDeleted() {
        state.toast = Toast(text: Localizations.itemSoftDeleted)
    }
}
