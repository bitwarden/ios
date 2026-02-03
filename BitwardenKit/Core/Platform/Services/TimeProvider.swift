import Foundation

// MARK: - TimeProvider

/// A protocol wrapping the present time.
///
///    For regular builds, the `TimeProvider` should use the current time as `presentTime`.
///    When testing, this protocol allows the current time to be mocked with any `Date`.
///
public protocol TimeProvider: AnyObject {
    /// The present time expressed as a `Date`, according to the provider.
    ///
    var presentTime: Date { get }

    /// The monotonic time expressed as a `TimeInterval` since system boot.
    ///
    /// This time is based on `ProcessInfo.systemUptime` and cannot be affected by user
    /// clock changes, making it suitable for measuring elapsed time intervals securely.
    /// The value resets to 0 when the device reboots.
    ///
    var monotonicTime: TimeInterval { get }

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
public class CurrentTime: TimeProvider {
    public var presentTime: Date {
        .now
    }

    public var monotonicTime: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    public init() {}

    public func timeSince(_ date: Date) -> TimeInterval {
        presentTime.timeIntervalSince(date)
    }
}
