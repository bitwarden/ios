import XCTest

@testable import BitwardenKit

class FlightRecorderToastBannerStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `isToastBannerVisible` returns `false` when `activeLog` is `nil`.
    func test_isToastBannerVisible_activeLogNil() {
        let subject = FlightRecorderToastBannerState(activeLog: nil)

        XCTAssertFalse(subject.isToastBannerVisible)
    }

    /// `isToastBannerVisible` returns `true` when `activeLog` has `isBannerDismissed` as `false`.
    func test_isToastBannerVisible_notDismissed() {
        let activeLog = FlightRecorderData.LogMetadata(
            duration: .eightHours,
            startDate: Date(year: 2025, month: 11, day: 13),
        )
        let subject = FlightRecorderToastBannerState(activeLog: activeLog)

        XCTAssertTrue(subject.isToastBannerVisible)
    }

    /// `isToastBannerVisible` returns `false` when `activeLog` has `isBannerDismissed` as `true`.
    func test_isToastBannerVisible_dismissed() {
        var activeLog = FlightRecorderData.LogMetadata(
            duration: .eightHours,
            startDate: Date(year: 2025, month: 11, day: 13),
        )
        activeLog.isBannerDismissed = true
        let subject = FlightRecorderToastBannerState(activeLog: activeLog)

        XCTAssertFalse(subject.isToastBannerVisible)
    }
}
