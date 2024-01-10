import Foundation

/// A calculator to identify expired TOTP Codes.
///
enum TOTPExpirationCalculator {
    // MARK: Static Methods

    /// Checks if a given `TOTPCodeModel` is expired.
    ///
    /// - Parameters:
    ///   - codeModel: The TOTP code model to check for expiration.
    ///   - timeProvider: A data type to provide the current time.
    ///
    /// - Returns: A `Bool`, `true` if the code has expired, `false` if it is still valid.
    ///
    static func hasCodeExpired(
        _ codeModel: TOTPCodeModel,
        timeProvider: any TimeProvider
    ) -> Bool {
        let period = codeModel.period
        let codeGenerationDate = codeModel.codeGenerationDate
        let elapsedTimeSinceCalculation = timeProvider.timeSince(codeGenerationDate)
        let isOlderThanInterval = elapsedTimeSinceCalculation >= Double(period)
        let hasPastIntervalRefreshMark = remainingSeconds(using: Int(period))
            >= remainingSeconds(for: codeGenerationDate, using: Int(period))
        return isOlderThanInterval || hasPastIntervalRefreshMark
    }

    /// Sorts a list of `VaultListItem` by expiration state
    ///
    /// - Parameters:
    ///   - items: An array of list items that may be expired.
    ///   - period: The interval after which the codes are expired.
    ///   - timeProvider: The provider of the current time.
    ///
    /// - Returns: A dictionary with the items sorted by a `Bool` flag indicating expiration.
    ///
    static func listItemsByExpiration(
        _ items: [VaultListItem],
        timeProvider: any TimeProvider
    ) -> [Bool: [VaultListItem]] {
        let sortedItems: [Bool: [VaultListItem]] = Dictionary(grouping: items, by: { item in
            guard case let .totp(_, model) = item.itemType else { return false }
            return hasCodeExpired(model.totpCode, timeProvider: timeProvider)
        })
        return sortedItems
    }

    /// Calculates the seconds remaining before an update is needed
    ///
    /// - Parameters:
    ///   - date: The date used to calculate the remaining seconds.
    ///   - period: The period of expiration.
    ///
    static func remainingSeconds(for date: Date = Date(), using period: Int) -> Int {
        period - (Int(date.timeIntervalSinceReferenceDate) % period)
    }
}
