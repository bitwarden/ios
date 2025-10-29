import BitwardenKit
import Combine
import Foundation

/// A protocol to manage TOTP code expirations for the ItemListProcessor and batch refresh calls.
///
protocol TOTPExpirationManager {
    // MARK: Properties

    /// A closure to call on expiration
    ///
    var onExpiration: (([ItemListItem]) -> Void)? { get set }

    // MARK: Methods

    /// Removes any outstanding timers
    ///
    func cleanup()

    /// Configures TOTP code refresh scheduling
    ///
    /// - Parameter items: The vault list items that may require code expiration tracking.
    ///
    func configureTOTPRefreshScheduling(for items: [ItemListItem])
}

/// A class to manage TOTP code expirations for the ItemListProcessor and batch refresh calls.
///
class DefaultTOTPExpirationManager: TOTPExpirationManager {
    // MARK: Private Properties

    /// A cancellable object used to manage the publisher subscription.
    private var cancellable: AnyCancellable?

    /// All items managed by the object, grouped by TOTP period.
    ///
    private(set) var itemsByInterval = [UInt32: [ItemListItem]]()

    /// A closure to call on expiration
    ///
    var onExpiration: (([ItemListItem]) -> Void)?

    /// A model to provide time to calculate the countdown.
    ///
    private var timeProvider: any TimeProvider

    /// A timer that triggers `checkForExpirations` to manage code expirations.
    ///
    private var updateTimer: Timer?

    /// Initializes a new countdown timer
    ///
    /// - Parameters
    ///   - itemPublisher: A publisher that emits the current list of vault sections whenever they change.
    ///   - timeProvider: A protocol providing the present time as a `Date`.
    ///         Used to calculate time remaining for a present TOTP code.
    ///   - onExpiration: A closure to call on code expiration for a list of vault items.
    ///
    init(
        itemPublisher: AnyPublisher<[ItemListSection]?, Never>,
        onExpiration: (([ItemListItem]) -> Void)?,
        timeProvider: any TimeProvider,
    ) {
        self.timeProvider = timeProvider
        self.onExpiration = onExpiration
        updateTimer = Timer.scheduledTimer(
            withTimeInterval: 0.25,
            repeats: true,
            block: { _ in
                self.checkForExpirations()
            },
        )
        cancellable = itemPublisher.sink { [weak self] sections in
            self?.configureTOTPRefreshScheduling(for: sections?.flatMap(\.items) ?? [])
        }
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
    func configureTOTPRefreshScheduling(for items: [ItemListItem]) {
        var newItemsByInterval = [UInt32: [ItemListItem]]()
        items.forEach { item in
            if let totpCodeModel = item.totpCodeModel {
                newItemsByInterval[totpCodeModel.period, default: []].append(item)
            }
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
        var expired = [ItemListItem]()
        var notExpired = [UInt32: [ItemListItem]]()
        itemsByInterval.forEach { period, items in
            let sortedItems: [Bool: [ItemListItem]] = TOTPExpirationCalculator.listItemsByExpiration(
                items,
                timeProvider: timeProvider,
            )
            expired.append(contentsOf: sortedItems[true] ?? [])
            notExpired[period] = sortedItems[false]
        }
        itemsByInterval = notExpired
        guard !expired.isEmpty else { return }
        onExpiration?(expired)
    }
}
