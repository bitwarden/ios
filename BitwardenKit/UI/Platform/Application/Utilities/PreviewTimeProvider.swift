import SwiftUI

#if DEBUG
/// A `TimeProvider` for previews.
///
public class PreviewTimeProvider: TimeProvider {
    /// A fixed date to use for previews.
    public var fixedDate: Date

    /// The current monotonic time.
    public var monotonicTime: TimeInterval

    public var presentTime: Date {
        fixedDate
    }

    public init(
        fixedDate: Date = .init(
            timeIntervalSinceReferenceDate: 1_695_000_011,
        ),
        monotonicTime: TimeInterval = 0,
    ) {
        self.fixedDate = fixedDate
        self.monotonicTime = monotonicTime
    }

    public func calculateTamperResistantElapsedTime(
        since lastMonotonicTime: TimeInterval,
        lastWallClockTime: Date,
        divergenceThreshold: TimeInterval,
    ) -> TamperResistantTimeResult {
        TamperResistantTimeResult(
            tamperingDetected: false,
            effectiveElapsed: 10,
            elapsedMonotonic: 10,
            elapsedWallClock: 10,
            divergence: 0,
        )
    }

    public func timeSince(_ date: Date) -> TimeInterval {
        presentTime.timeIntervalSince(date)
    }
}
#endif
