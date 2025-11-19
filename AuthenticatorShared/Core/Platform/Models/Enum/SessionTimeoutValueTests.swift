import BitwardenKit
import BitwardenResources
import XCTest

@testable import AuthenticatorShared

final class SessionTimeoutValueTests: BitwardenTestCase {
    // MARK: Tests

    /// `allCases` returns all of the cases in the correct order.
    func test_allCases() {
        XCTAssertEqual(
            SessionTimeoutValue.allCases,
            [
                .immediately,
                .oneMinute,
                .fiveMinutes,
                .fifteenMinutes,
                .thirtyMinutes,
                .oneHour,
                .fourHours,
                .onAppRestart,
                .never,
            ],
        )
    }

    /// `localizedName` returns the correct values.
    func test_localizedName() {
        XCTAssertEqual(SessionTimeoutValue.immediately.localizedName, Localizations.immediately)
        XCTAssertEqual(SessionTimeoutValue.oneMinute.localizedName, Localizations.xMinutes(1))
        XCTAssertEqual(SessionTimeoutValue.fiveMinutes.localizedName, Localizations.xMinutes(5))
        XCTAssertEqual(SessionTimeoutValue.fifteenMinutes.localizedName, Localizations.xMinutes(15))
        XCTAssertEqual(SessionTimeoutValue.thirtyMinutes.localizedName, Localizations.xMinutes(30))
        XCTAssertEqual(SessionTimeoutValue.oneHour.localizedName, Localizations.xHours(1))
        XCTAssertEqual(SessionTimeoutValue.fourHours.localizedName, Localizations.xHours(4))
        XCTAssertEqual(SessionTimeoutValue.onAppRestart.localizedName, Localizations.onRestart)
        XCTAssertEqual(SessionTimeoutValue.never.localizedName, Localizations.never)
        XCTAssertEqual(SessionTimeoutValue.custom(123).localizedName, Localizations.custom)
    }
}
