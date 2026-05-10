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
    /// This time is based on `clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)` and cannot be affected
    /// by user clock changes, making it suitable for measuring elapsed time intervals securely.
    /// Unlike `ProcessInfo.systemUptime`, this clock continues to advance during device
    /// sleep, preventing false tamper-detection divergence when the device wakes.
    /// The value resets to 0 when the device reboots.
    ///
    /// - Note: On Darwin, `CLOCK_MONOTONIC_RAW` is equivalent to `mach_continuous_time()` —
    ///   it includes time while the device is asleep.
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
        lastMonotonicTime: TimeInterval,
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
        Double(clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)) / 1_000_000_000
    }

    // MARK: Init

    public init() {}

    // MARK: Methods

    public func calculateTamperResistantElapsedTime(
        lastMonotonicTime: TimeInterval,
        lastWallClockTime: Date,
        divergenceThreshold: TimeInterval = 5.0,
    ) -> TamperResistantTimeResult {
        let elapsedMonotonic = monotonicTime - lastMonotonicTime
        let elapsedWallClock = presentTime.timeIntervalSince(lastWallClockTime)
        let divergence = abs(elapsedWallClock - elapsedMonotonic)

        // A negative monotonic elapsed time means the device rebooted since the last active time.
        // Monotonic time resets to ~0 on reboot, so current < stored → negative result.
        let isReboot = elapsedMonotonic < 0

        // Detect reboot or obvious clock manipulation via divergence
        let tamperingDetected = isReboot || divergence > divergenceThreshold

        // Use monotonic time exclusively as the tamper-resistant source for the timeout decision.
        // Wall-clock is retained only for divergence detection (anomaly signaling).
        let effectiveElapsed = elapsedMonotonic

        return TamperResistantTimeResult(
            divergence: divergence,
            effectiveElapsed: effectiveElapsed,
            elapsedMonotonic: elapsedMonotonic,
            elapsedWallClock: elapsedWallClock,
            isReboot: isReboot,
            tamperingDetected: tamperingDetected,
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
    /// The divergence threshold default is 5.0 seconds, which is well above normal NTP corrections
    /// (typically < 500ms) while still providing a tight anomaly detection window.
    ///
    /// - Parameters:
    ///   - lastMonotonicTime: The previously stored monotonic time (seconds since boot).
    ///   - lastWallClockTime: The previously stored wall-clock time.
    /// - Returns: A `TamperResistantTimeResult` containing tampering detection status and elapsed times.
    ///
    func calculateTamperResistantElapsedTime(
        lastMonotonicTime: TimeInterval,
        lastWallClockTime: Date,
    ) -> TamperResistantTimeResult {
        calculateTamperResistantElapsedTime(
            lastMonotonicTime: lastMonotonicTime,
            lastWallClockTime: lastWallClockTime,
            divergenceThreshold: 5.0,
        )
    }
}

// MARK: - TamperResistantTimeResult

/// Result of tamper-resistant elapsed time calculation.
public struct TamperResistantTimeResult {
    // MARK: Properties

    /// The divergence between the two clocks.
    public let divergence: TimeInterval

    /// The effective elapsed time to use, derived exclusively from the monotonic clock.
    public let effectiveElapsed: TimeInterval

    /// The elapsed time according to monotonic clock.
    public let elapsedMonotonic: TimeInterval

    /// The elapsed time according to wall-clock.
    public let elapsedWallClock: TimeInterval

    /// Whether the device was rebooted since the last active time was recorded.
    ///
    /// A reboot is detected when `elapsedMonotonic` is negative, meaning the stored monotonic
    /// time is greater than the current monotonic time (which resets to ~0 on each boot).
    ///
    public let isReboot: Bool

    /// Whether clock manipulation or device reboot was detected.
    public let tamperingDetected: Bool

    // MARK: Init

    /// Initializes a `TamperResistantTimeResult`.
    /// - Parameters:
    ///   - divergence: The divergence between the two clocks.
    ///   - effectiveElapsed: The effective elapsed time, derived exclusively from the monotonic clock.
    ///   - elapsedMonotonic: The elapsed time according to monotonic clock.
    ///   - elapsedWallClock: The elapsed time according to wall-clock.
    ///   - isReboot: Whether the device was rebooted since the last active time was recorded.
    ///   - tamperingDetected: Whether clock manipulation or device reboot was detected.
    public init(
        divergence: TimeInterval,
        effectiveElapsed: TimeInterval,
        elapsedMonotonic: TimeInterval,
        elapsedWallClock: TimeInterval,
        isReboot: Bool,
        tamperingDetected: Bool,
    ) {
        self.divergence = divergence
        self.effectiveElapsed = effectiveElapsed
        self.elapsedMonotonic = elapsedMonotonic
        self.elapsedWallClock = elapsedWallClock
        self.isReboot = isReboot
        self.tamperingDetected = tamperingDetected
    }
}
