import XCTest

@testable import BitwardenKit

class FlightRecorderToastBannerStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `activeLog` didSet hides the toast banner when `activeLog` is set to `nil`.
    func test_activeLog_didSet_nil() {
        var subject = FlightRecorderToastBannerState(
            activeLog: FlightRecorderData.LogMetadata(
                duration: .eightHours,
                startDate: Date(year: 2025, month: 11, day: 13),
            ),
            isToastBannerVisible: true,
        )

        subject.activeLog = nil

        XCTAssertNil(subject.activeLog)
        XCTAssertFalse(subject.isToastBannerVisible)
    }

    /// `activeLog` didSet shows the toast banner when `activeLog` is set to a log with
    /// `isBannerDismissed` as `false`.
    func test_activeLog_didSet_notDismissed() {
        var subject = FlightRecorderToastBannerState()

        let activeLog = FlightRecorderData.LogMetadata(
            duration: .eightHours,
            startDate: Date(year: 2025, month: 11, day: 13),
        )
        subject.activeLog = activeLog

        XCTAssertEqual(subject.activeLog, activeLog)
        XCTAssertTrue(subject.isToastBannerVisible)
    }

    /// `activeLog` didSet hides the toast banner when `activeLog` is set to a log with
    /// `isBannerDismissed` as `true`.
    func test_activeLog_didSet_dismissed() {
        var subject = FlightRecorderToastBannerState()

        var activeLog = FlightRecorderData.LogMetadata(
            duration: .eightHours,
            startDate: Date(year: 2025, month: 11, day: 13),
        )
        activeLog.isBannerDismissed = true
        subject.activeLog = activeLog

        XCTAssertEqual(subject.activeLog, activeLog)
        XCTAssertFalse(subject.isToastBannerVisible)
    }

    /// `activeLog` didSet updates the visibility when the log is changed to a different log.
    func test_activeLog_didSet_changedLog() {
        var subject = FlightRecorderToastBannerState(
            activeLog: FlightRecorderData.LogMetadata(
                duration: .eightHours,
                startDate: Date(year: 2025, month: 11, day: 13),
            ),
            isToastBannerVisible: false,
        )

        let newActiveLog = FlightRecorderData.LogMetadata(
            duration: .twentyFourHours,
            startDate: Date(year: 2025, month: 11, day: 14),
        )
        subject.activeLog = newActiveLog

        XCTAssertEqual(subject.activeLog, newActiveLog)
        XCTAssertTrue(subject.isToastBannerVisible)
    }
}
