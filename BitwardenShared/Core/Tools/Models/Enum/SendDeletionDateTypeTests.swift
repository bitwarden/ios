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

        let fourteenDays = SendDeletionDateType.fourteenDays.calculateDate(from: originDate)
        XCTAssertEqual(fourteenDays, Date(year: 2023, month: 11, day: 19))

        let thirtyDays = SendDeletionDateType.thirtyDays.calculateDate(from: originDate)
        XCTAssertEqual(thirtyDays, Date(year: 2023, month: 12, day: 5))

        let custom = SendDeletionDateType.custom(customDate).calculateDate(from: originDate)
        XCTAssertEqual(custom, customDate)
    }

    /// `from(hours:)` maps a preset number of hours to the matching preset case.
    func test_fromHours_presets() {
        let originDate = Date(year: 2023, month: 11, day: 5)
        XCTAssertEqual(SendDeletionDateType.from(hours: 1, originDate: originDate), .oneHour)
        XCTAssertEqual(SendDeletionDateType.from(hours: 24, originDate: originDate), .oneDay)
        XCTAssertEqual(SendDeletionDateType.from(hours: 48, originDate: originDate), .twoDays)
        XCTAssertEqual(SendDeletionDateType.from(hours: 72, originDate: originDate), .threeDays)
        XCTAssertEqual(SendDeletionDateType.from(hours: 168, originDate: originDate), .sevenDays)
        XCTAssertEqual(SendDeletionDateType.from(hours: 336, originDate: originDate), .fourteenDays)
        XCTAssertEqual(SendDeletionDateType.from(hours: 720, originDate: originDate), .thirtyDays)
    }

    /// `from(hours:)` falls back to a custom date `hours` from the origin date when the number of
    /// hours doesn't match a preset.
    func test_fromHours_customFallback() {
        let originDate = Date(year: 2023, month: 11, day: 5)
        XCTAssertEqual(
            SendDeletionDateType.from(hours: 100, originDate: originDate),
            .custom(Date(year: 2023, month: 11, day: 9, hour: 4)),
        )
    }

    /// `localizedName` returns the localized name of the option to display in the menu.
    func test_localizedName() {
        XCTAssertEqual(SendDeletionDateType.oneHour.localizedName, Localizations.xHours(1))
        XCTAssertEqual(SendDeletionDateType.oneDay.localizedName, Localizations.xDays(1))
        XCTAssertEqual(SendDeletionDateType.twoDays.localizedName, Localizations.xDays(2))
        XCTAssertEqual(SendDeletionDateType.threeDays.localizedName, Localizations.xDays(3))
        XCTAssertEqual(SendDeletionDateType.sevenDays.localizedName, Localizations.xDays(7))
        XCTAssertEqual(SendDeletionDateType.fourteenDays.localizedName, Localizations.xDays(14))
        XCTAssertEqual(SendDeletionDateType.thirtyDays.localizedName, Localizations.xDays(30))

        XCTAssertEqual(
            SendDeletionDateType.custom(Date(year: 2024, month: 1, day: 19)).localizedName,
            "Jan 19, 2024, 12:00\u{202F}AM",
        )
        XCTAssertEqual(
            SendDeletionDateType.custom(Date(year: 2024, month: 6, day: 10)).localizedName,
            "Jun 10, 2024, 12:00\u{202F}AM",
        )
    }
}
