import SwiftUI

#if DEBUG
/// A `TimeProvider` for previews.
///
public class PreviewTimeProvider: TimeProvider {
    /// A fixed date to use for previews.
    public var fixedDate: Date

    /// THe current monotonic time.
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

    public func timeSince(_ date: Date) -> TimeInterval {
        presentTime.timeIntervalSince(date)
    }
}
#endif
