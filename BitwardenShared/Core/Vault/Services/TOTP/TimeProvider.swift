import Foundation

// MARK: - TimeProvider

/// A protocol wrapping the present time.
///
///    For regular builds, the `TimeProvider` should use the current time as `presentTime`.
///    When testing, this protocol allows the current time to be mocked with any `Date`.
///
protocol TimeProvider: AnyObject {
    /// The present time expressed as a `Date`, according to the provider.
    ///
    var presentTime: Date { get }

    /// A helper to calculate the elapsed time since a given `Date`.
    ///
    /// - Parameter date: The time to compare with the provider's `presentTime`
    /// - Returns: A `TimeInterval` of the duration between the two dates.
    ///
    func timeSince(_ date: Date) -> TimeInterval
}

// MARK: - CurrentTime

/// A `TimeProvider` that returns the current time whenever `presentTime` is read.
///
class CurrentTime: TimeProvider {
    var presentTime: Date {
        .now
    }

    func timeSince(_ date: Date) -> TimeInterval {
        presentTime.timeIntervalSince(date)
    }
}
