import BitwardenKit
import Foundation

// MARK: - TOTPExpirationCalculator + VaultListItem

extension TOTPExpirationCalculator {
    /// Sorts a list of `VaultListItem` by expiration state.
    ///
    /// - Parameters:
    ///   - items: An array of list items that may be expired.
    ///   - timeProvider: The provider of the current time.
    ///
    /// - Returns: A dictionary with the items sorted by a `Bool` flag indicating expiration.
    ///
    static func listItemsByExpiration(
        _ items: [VaultListItem],
        timeProvider: any TimeProvider,
    ) -> [Bool: [VaultListItem]] {
        Dictionary(grouping: items, by: { item in
            guard case let .totp(_, model) = item.itemType else { return false }
            return hasCodeExpired(model.totpCode, timeProvider: timeProvider)
        })
    }
}
