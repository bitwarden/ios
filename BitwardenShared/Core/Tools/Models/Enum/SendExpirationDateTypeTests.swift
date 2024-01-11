import XCTest

@testable import BitwardenShared

// MARK: - SendExpirationDateTypeTests

class SendExpirationDateTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `calculateDate()` returns the correct date.
    func test_calculateDate() {
        let originDate = Date(year: 2023, month: 11, day: 5)
        let customDate = Date(year: 2024, month: 1, day: 19)

        let never = SendExpirationDateType.never.calculateDate(from: originDate, customValue: customDate)
        XCTAssertNil(never)

        let oneHour = SendExpirationDateType.oneHour.calculateDate(from: originDate, customValue: customDate)
        XCTAssertEqual(oneHour, Date(year: 2023, month: 11, day: 5, hour: 1))

        let oneDay = SendExpirationDateType.oneDay.calculateDate(from: originDate, customValue: customDate)
        XCTAssertEqual(oneDay, Date(year: 2023, month: 11, day: 6))

        let twoDays = SendExpirationDateType.twoDays.calculateDate(from: originDate, customValue: customDate)
        XCTAssertEqual(twoDays, Date(year: 2023, month: 11, day: 7))

        let threeDays = SendExpirationDateType.threeDays.calculateDate(from: originDate, customValue: customDate)
        XCTAssertEqual(threeDays, Date(year: 2023, month: 11, day: 8))

        let sevenDays = SendExpirationDateType.sevenDays.calculateDate(from: originDate, customValue: customDate)
        XCTAssertEqual(sevenDays, Date(year: 2023, month: 11, day: 12))

        let thirtyDays = SendExpirationDateType.thirtyDays.calculateDate(from: originDate, customValue: customDate)
        XCTAssertEqual(thirtyDays, Date(year: 2023, month: 12, day: 5))

        let custom = SendExpirationDateType.custom.calculateDate(from: originDate, customValue: customDate)
        XCTAssertEqual(custom, Date(year: 2024, month: 1, day: 19))
    }
}
