import Foundation

// MARK: - TimeProvider

/// A protocol wrapping the present time.
///
///    For regular builds, the `TimeProvider` should use the current time as `presentTime`.
///    When testing, this protocol allows the current time to be mocked with any `Date`.
///
public protocol TimeProvider: AnyObject {
    // MARK: Properties

    /// The monotonic time expressed as a `TimeInterval` since system boot.
    ///
    /// This time is based on `ProcessInfo.systemUptime` and cannot be affected by user
    /// clock changes, making it suitable for measuring elapsed time intervals securely.
    /// The value resets to 0 when the device reboots.
    ///
    var monotonicTime: TimeInterval { get }

    /// The present time expressed as a `Date`, according to the provider.
    ///
    var presentTime: Date { get }

    // MARK: Methods

    /// Calculates elapsed time using both monotonic and wall-clock time for tamper-resistance.
    ///
    /// This method detects clock manipulation and device reboots by comparing elapsed time
    /// from both the monotonic clock (unaffected by user clock changes) and wall-clock time.
    /// If the divergence between the two exceeds the threshold, tampering is detected.
    ///
    /// - Parameters:
    ///   - lastMonotonicTime: The previously stored monotonic time (seconds since boot).
    ///   - lastWallClockTime: The previously stored wall-clock time.
    ///   - divergenceThreshold: Maximum allowed divergence between the two clocks in seconds.
    /// - Returns: A `TamperResistantTimeResult` containing tampering detection status and elapsed times.
    ///
    func calculateTamperResistantElapsedTime(
        since lastMonotonicTime: TimeInterval,
        lastWallClockTime: Date,
        divergenceThreshold: TimeInterval,
    ) -> TamperResistantTimeResult

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
    // MARK: Properties

    public var presentTime: Date {
        .now
    }

    public var monotonicTime: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }

    // MARK: Init

    public init() {}

    // MARK: - Methods

    public func calculateTamperResistantElapsedTime(
        since lastMonotonicTime: TimeInterval,
        lastWallClockTime: Date,
        divergenceThreshold: TimeInterval = 15.0,
    ) -> TamperResistantTimeResult {
        let elapsedMonotonic = monotonicTime - lastMonotonicTime
        let elapsedWallClock = presentTime.timeIntervalSince(lastWallClockTime)
        let divergence = abs(elapsedWallClock - elapsedMonotonic)

        // Detect reboot or clock manipulation via divergence
        let tamperingDetected = divergence > divergenceThreshold

        // Use maximum of both clocks for extra safety against small manipulations
        let effectiveElapsed = max(elapsedMonotonic, elapsedWallClock)

        return TamperResistantTimeResult(
            tamperingDetected: tamperingDetected,
            effectiveElapsed: effectiveElapsed,
            elapsedMonotonic: elapsedMonotonic,
            elapsedWallClock: elapsedWallClock,
            divergence: divergence,
        )
    }

    public func timeSince(_ date: Date) -> TimeInterval {
        presentTime.timeIntervalSince(date)
    }
}

// MARK: - TimeProvider Tamper-Resistant Extensions

public extension TimeProvider {
    /// Calculates elapsed time using both monotonic and wall-clock time for tamper-resistance.
    ///
    /// This method detects clock manipulation and device reboots by comparing elapsed time
    /// from both the monotonic clock (unaffected by user clock changes) and wall-clock time.
    /// If the divergence between the two exceeds the threshold, tampering is detected.
    /// The divergence threshold default is 15.0 seconds to account for legitimate NTP corrections.
    ///
    /// - Parameters:
    ///   - lastMonotonicTime: The previously stored monotonic time (seconds since boot).
    ///   - lastWallClockTime: The previously stored wall-clock time.
    /// - Returns: A `TamperResistantTimeResult` containing tampering detection status and elapsed times.
    ///
    func calculateTamperResistantElapsedTime(
        since lastMonotonicTime: TimeInterval,
        lastWallClockTime: Date,
    ) -> TamperResistantTimeResult {
        calculateTamperResistantElapsedTime(
            since: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 15.0,
        )
    }
}

// MARK: - TamperResistantTimeResult

/// Result of tamper-resistant elapsed time calculation.
public struct TamperResistantTimeResult {
    // MARK: Properties

    /// Whether clock manipulation or device reboot was detected.
    public let tamperingDetected: Bool

    /// The effective elapsed time to use (max of both clocks if no tampering detected).
    public let effectiveElapsed: TimeInterval

    /// The elapsed time according to monotonic clock.
    public let elapsedMonotonic: TimeInterval

    /// The elapsed time according to wall-clock.
    public let elapsedWallClock: TimeInterval

    /// The divergence between the two clocks.
    public let divergence: TimeInterval

    // MARK: Init

    public init(
        tamperingDetected: Bool,
        effectiveElapsed: TimeInterval,
        elapsedMonotonic: TimeInterval,
        elapsedWallClock: TimeInterval,
        divergence: TimeInterval,
    ) {
        self.tamperingDetected = tamperingDetected
        self.effectiveElapsed = effectiveElapsed
        self.elapsedMonotonic = elapsedMonotonic
        self.elapsedWallClock = elapsedWallClock
        self.divergence = divergence
    }
}
