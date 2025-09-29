import BitwardenResources
import XCTest

@testable import BitwardenShared

class AboutStateTests: BitwardenTestCase {
    /// `flightRecorderToggleAccessibilityLabel` returns the flight recorder toggle's accessibility
    /// label when the flight recorder is off.
    func test_flightRecorderToggleAccessibilityLabel_flightRecorderOff() {
        let subject = AboutState(flightRecorderActiveLog: nil)
        XCTAssertEqual(subject.flightRecorderToggleAccessibilityLabel, Localizations.flightRecorder)
    }

    /// `flightRecorderToggleAccessibilityLabel` returns the flight recorder toggle's accessibility
    /// label when the flight recorder is on.
    func test_flightRecorderToggleAccessibilityLabel_flightRecorderOn() {
        let subject = AboutState(
            flightRecorderActiveLog: FlightRecorderData.LogMetadata(
                duration: .eightHours,
                startDate: Date(year: 2025, month: 5, day: 1)
            )
        )
        XCTAssertEqual(
            subject.flightRecorderToggleAccessibilityLabel,
            Localizations.flightRecorder + ", Logging ends on May 1, 2025 at 8:00 AM"
        )
    }
}
