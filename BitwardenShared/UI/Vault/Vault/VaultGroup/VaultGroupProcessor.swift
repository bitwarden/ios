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
        totpExpirationManager = .init(onExpiration: { [weak self] expiredItems in
            guard let self else { return }
            Task {
                await self.refreshTOTPCodes(for: expiredItems)
            }
        })
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
                totpExpirationManager?.configureTOTPRefreshScheduling(for: value)
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
            case let .totp(_, model):
                coordinator.navigate(to: .viewItem(id: model.id))
            }
        case let .morePressed(item):
            // TODO: BIT-375 Show the more menu
            print("more: \(item.id)")
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

    /// A timer that triggers `checkForExpirations` to manage code expirations.
    ///
    private var updateTimer: Timer?

    /// Initializes a new countdown timer
    ///
    /// - Parameters
    ///   - onExpiration: A closure to call on code expiration for a list of vault items.
    ///
    init(
        onExpiration: (([VaultListItem]) -> Void)?
    ) {
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
                let elapsedCodeTime = model.totpCode.date.timeIntervalSinceNow * -1.0
                let isOlderThanInterval = elapsedCodeTime >= Double(period)
                let hasPastIntervalRefreshMark = remainingSeconds(using: Int(period))
                    >= remainingSeconds(for: model.totpCode.date, using: Int(period))
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
