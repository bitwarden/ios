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

    /// An object to manage TOTP code expirations and batch refresh calls.
    private var totpExpirationManager: TOTPExpirationManager?

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
        totpExpirationManager = .init(
            timeProvider: services.vaultRepository.timeProvider,
            onExpiration: { [weak self] expiredItems in
                guard let self else { return }
                Task {
                    await self.refreshTOTPCodes(for: expiredItems)
                }
            }
        )
    }

    deinit {
        totpExpirationManager?.cleanup()
        totpExpirationManager = nil
    }

    // MARK: Methods

    override func perform(_ effect: VaultGroupEffect) async {
        switch effect {
        case .appeared:
            for await value in services.vaultRepository.vaultListPublisher(group: state.group) {
                let sortedValues = value
                    .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                totpExpirationManager?.configureTOTPRefreshScheduling(for: sortedValues)
                state.loadingState = .data(sortedValues)
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
        case let .copyTOTPCode(code):
            services.pasteboardService.copy(code)
            state.toast = Toast(text: Localizations.valueHasBeenCopied(Localizations.verificationCode))
        case let .itemPressed(item):
            switch item.itemType {
            case .cipher:
                coordinator.navigate(to: .viewItem(id: item.id), context: self)
            case let .group(group, _):
                coordinator.navigate(to: .group(group))
            case let .totp(_, model):
                coordinator.navigate(to: .viewItem(id: model.id))
            }
        case let .searchTextChanged(newValue):
            state.searchText = newValue
        case let .toastShown(newValue):
            state.toast = newValue
        }
    }

    // MARK: Private Methods

    /// Refreshes the vault group's TOTP Codes.
    ///
    private func refreshTOTPCodes(for items: [VaultListItem]) async {
        guard case let .data(currentItems) = state.loadingState else { return }
        do {
            let refreshedItems = try await services.vaultRepository.refreshTOTPCodes(for: items)
            let allItems = currentItems.updated(with: refreshedItems)
            totpExpirationManager?.configureTOTPRefreshScheduling(for: allItems)
            state.loadingState = .data(allItems)
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
            let sortedItems: [Bool: [VaultListItem]] = Dictionary(grouping: items, by: { item in
                guard case let .totp(_, model) = item.itemType else { return false }
                let elapsedTimeSinceCalculation = timeProvider.timeSince(model.totpCode.codeGenerationDate)
                let isOlderThanInterval = elapsedTimeSinceCalculation >= Double(period)
                let hasPastIntervalRefreshMark = remainingSeconds(using: Int(period))
                    >= remainingSeconds(for: model.totpCode.codeGenerationDate, using: Int(period))
                return isOlderThanInterval || hasPastIntervalRefreshMark
            })
            expired.append(contentsOf: sortedItems[true] ?? [])
            notExpired[period] = sortedItems[false]
        }
        itemsByInterval = notExpired
        guard !expired.isEmpty else { return }
        onExpiration?(expired)
    }

    /// Calculates the seconds remaining before an update is needed.
    ///
    /// - Parameters:
    ///   - date: The date used to calculate the remaining seconds.
    ///   - period: The period of expiration.
    ///
    private func remainingSeconds(for date: Date = Date(), using period: Int) -> Int {
        period - (Int(date.timeIntervalSinceReferenceDate) % period)
    }
}
