import BitwardenKit
import Foundation

// MARK: - TOTPExpirationCalculator + ItemListItem

extension TOTPExpirationCalculator {
    /// Sorts a list of `ItemListItem` by expiration state.
    ///
    /// - Parameters:
    ///   - items: An array of list items that may be expired.
    ///   - timeProvider: The provider of the current time.
    ///
    /// - Returns: A dictionary with the items sorted by a `Bool` flag indicating expiration.
    ///
    static func listItemsByExpiration(
        _ items: [ItemListItem],
        timeProvider: any TimeProvider,
    ) -> [Bool: [ItemListItem]] {
        Dictionary(grouping: items, by: { item in
            guard let totpCode = item.totpCodeModel else { return false }
            return hasCodeExpired(totpCode, timeProvider: timeProvider)
        })
    }
}
