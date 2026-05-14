import Foundation

// MARK: - TOTPExpirationCalculator

/// A calculator to identify expired TOTP codes.
///
public enum TOTPExpirationCalculator {
    // MARK: Static Methods

    /// Checks if a given `TOTPCodeModel` is expired.
    ///
    /// - Parameters:
    ///   - codeModel: The TOTP code model to check for expiration.
    ///   - timeProvider: A data type to provide the current time.
    ///
    /// - Returns: A `Bool`, `true` if the code has expired, `false` if it is still valid.
    ///
    public static func hasCodeExpired(
        _ codeModel: TOTPCodeModel,
        timeProvider: any TimeProvider,
    ) -> Bool {
        let period = codeModel.period
        let codeGenerationDate = codeModel.codeGenerationDate

        // The time interval until a code generated at the `codeGenerationDate` would need a refresh.
        let codeGenerationDateTimeRemaining = timeRemaining(for: codeGenerationDate, using: Double(period))

        // The date after which the codeModel would need a refresh.
        let codeRefreshCutoffDate = codeGenerationDate.addingTimeInterval(codeGenerationDateTimeRemaining)

        // Check if the cutoff date has past.
        let hasCodeExpired = codeRefreshCutoffDate <= timeProvider.presentTime

        return hasCodeExpired
    }

    /// Calculates the seconds remaining before an update is needed.
    ///
    /// - Parameters:
    ///   - date: The date used to calculate the remaining seconds.
    ///   - period: The period of expiration.
    ///
    /// - Returns: The number of seconds remaining, expressed as an integer.
    ///
    public static func remainingSeconds(for date: Date, using period: Int) -> Int {
        Int(ceil(timeRemaining(for: date, using: Double(period))))
    }

    /// Calculates the time interval remaining before an update is needed.
    ///
    /// - Parameters:
    ///   - date: The date used to calculate the remaining seconds.
    ///   - period: The period of expiration.
    ///
    /// - Returns: The time remaining, expressed as a `TimeInterval`.
    ///
    public static func timeRemaining(for date: Date, using period: TimeInterval) -> TimeInterval {
        let interval = date.timeIntervalSinceReferenceDate
        let remainder = interval.truncatingRemainder(dividingBy: period)
        return Double(period) - remainder
    }
}
