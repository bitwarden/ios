import SwiftUI

#if DEBUG
/// A `TimeProvider` for previews.
///
class PreviewTimeProvider: TimeProvider {
    /// A fixed date to use for previews.
    var fixedDate: Date

    var presentTime: Date {
        fixedDate
    }

    init(
        fixedDate: Date = .init(
            timeIntervalSinceReferenceDate: 1_695_000_011
        )
    ) {
        self.fixedDate = fixedDate
    }

    func timeSince(_ date: Date) -> TimeInterval {
        presentTime.timeIntervalSince(date)
    }
}
#endif
