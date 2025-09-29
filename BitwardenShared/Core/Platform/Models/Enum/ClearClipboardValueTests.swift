import XCTest

import BitwardenResources
@testable import BitwardenShared

class ClearClipboardValueTests: BitwardenTestCase {
    // MARK: Tests

    /// `localizedName` returns the correct values.
    func test_localizedName() {
        XCTAssertEqual(ClearClipboardValue.never.localizedName, Localizations.never)
        XCTAssertEqual(ClearClipboardValue.tenSeconds.localizedName, Localizations.tenSeconds)
        XCTAssertEqual(ClearClipboardValue.twentySeconds.localizedName, Localizations.twentySeconds)
        XCTAssertEqual(ClearClipboardValue.thirtySeconds.localizedName, Localizations.thirtySeconds)
        XCTAssertEqual(ClearClipboardValue.oneMinute.localizedName, Localizations.xMinutes(1))
        XCTAssertEqual(ClearClipboardValue.twoMinutes.localizedName, Localizations.xMinutes(2))
        XCTAssertEqual(ClearClipboardValue.fiveMinutes.localizedName, Localizations.xMinutes(5))
    }

    /// `rawValue` returns the correct values.
    func test_rawValues() {
        XCTAssertEqual(ClearClipboardValue.never.rawValue, -1)
        XCTAssertEqual(ClearClipboardValue.tenSeconds.rawValue, 10)
        XCTAssertEqual(ClearClipboardValue.twentySeconds.rawValue, 20)
        XCTAssertEqual(ClearClipboardValue.thirtySeconds.rawValue, 30)
        XCTAssertEqual(ClearClipboardValue.oneMinute.rawValue, 60)
        XCTAssertEqual(ClearClipboardValue.twoMinutes.rawValue, 120)
        XCTAssertEqual(ClearClipboardValue.fiveMinutes.rawValue, 300)
    }
}
