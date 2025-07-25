import XCTest

import BitwardenResources
@testable import BitwardenShared

// MARK: - SendDeletionDateTypeTests

class SendDeletionDateTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `calculateDate()` returns the correct date.
    func test_calculateDate() {
        let originDate = Date(year: 2023, month: 11, day: 5)
        let customDate = Date(year: 2024, month: 1, day: 19)

        let oneHour = SendDeletionDateType.oneHour.calculateDate(from: originDate)
        XCTAssertEqual(oneHour, Date(year: 2023, month: 11, day: 5, hour: 1))

        let oneDay = SendDeletionDateType.oneDay.calculateDate(from: originDate)
        XCTAssertEqual(oneDay, Date(year: 2023, month: 11, day: 6))

        let twoDays = SendDeletionDateType.twoDays.calculateDate(from: originDate)
        XCTAssertEqual(twoDays, Date(year: 2023, month: 11, day: 7))

        let threeDays = SendDeletionDateType.threeDays.calculateDate(from: originDate)
        XCTAssertEqual(threeDays, Date(year: 2023, month: 11, day: 8))

        let sevenDays = SendDeletionDateType.sevenDays.calculateDate(from: originDate)
        XCTAssertEqual(sevenDays, Date(year: 2023, month: 11, day: 12))

        let thirtyDays = SendDeletionDateType.thirtyDays.calculateDate(from: originDate)
        XCTAssertEqual(thirtyDays, Date(year: 2023, month: 12, day: 5))

        let custom = SendDeletionDateType.custom(customDate).calculateDate(from: originDate)
        XCTAssertEqual(custom, customDate)
    }

    /// `localizedName` returns the localized name of the option to display in the menu.
    func test_localizedName() {
        XCTAssertEqual(SendDeletionDateType.oneHour.localizedName, Localizations.oneHour)
        XCTAssertEqual(SendDeletionDateType.oneDay.localizedName, Localizations.oneDay)
        XCTAssertEqual(SendDeletionDateType.twoDays.localizedName, Localizations.twoDays)
        XCTAssertEqual(SendDeletionDateType.threeDays.localizedName, Localizations.threeDays)
        XCTAssertEqual(SendDeletionDateType.sevenDays.localizedName, Localizations.sevenDays)
        XCTAssertEqual(SendDeletionDateType.thirtyDays.localizedName, Localizations.thirtyDays)

        XCTAssertEqual(
            SendDeletionDateType.custom(Date(year: 2024, month: 1, day: 19)).localizedName,
            "Jan 19, 2024, 12:00\u{202F}AM"
        )
        XCTAssertEqual(
            SendDeletionDateType.custom(Date(year: 2024, month: 6, day: 10)).localizedName,
            "Jun 10, 2024, 12:00\u{202F}AM"
        )
    }
}
