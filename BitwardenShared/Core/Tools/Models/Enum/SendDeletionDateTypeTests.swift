import XCTest

@testable import BitwardenShared

// MARK: - SendDeletionDateTypeTests

class SendDeletionDateTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `calculateDate()` returns the correct date.
    func test_calculateDate() {
        let originDate = Date(year: 2023, month: 11, day: 5)
        let customDate = Date(year: 2024, month: 1, day: 19)

        let oneHour = SendDeletionDateType.oneHour.calculateDate(from: originDate, customValue: customDate)
        XCTAssertEqual(oneHour, Date(year: 2023, month: 11, day: 5, hour: 1))

        let oneDay = SendDeletionDateType.oneDay.calculateDate(from: originDate, customValue: customDate)
        XCTAssertEqual(oneDay, Date(year: 2023, month: 11, day: 6))

        let twoDays = SendDeletionDateType.twoDays.calculateDate(from: originDate, customValue: customDate)
        XCTAssertEqual(twoDays, Date(year: 2023, month: 11, day: 7))

        let threeDays = SendDeletionDateType.threeDays.calculateDate(from: originDate, customValue: customDate)
        XCTAssertEqual(threeDays, Date(year: 2023, month: 11, day: 8))

        let sevenDays = SendDeletionDateType.sevenDays.calculateDate(from: originDate, customValue: customDate)
        XCTAssertEqual(sevenDays, Date(year: 2023, month: 11, day: 12))

        let thirtyDays = SendDeletionDateType.thirtyDays.calculateDate(from: originDate, customValue: customDate)
        XCTAssertEqual(thirtyDays, Date(year: 2023, month: 12, day: 5))

        let custom = SendDeletionDateType.custom.calculateDate(from: originDate, customValue: customDate)
        XCTAssertEqual(custom, Date(year: 2024, month: 1, day: 19))
    }
}
