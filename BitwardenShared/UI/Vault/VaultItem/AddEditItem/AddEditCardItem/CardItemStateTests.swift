import TestHelpers
import XCTest

@testable import BitwardenShared

class CardItemStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `expirationString` returns the card's formatted expiration string when the year and month
    /// are both empty.
    func test_expirationString_empty() {
        let subject = CardItemState()

        XCTAssertEqual(subject.expirationString, "")
    }

    /// `expirationString` returns the card's formatted expiration string when the year and month
    /// are both populated.
    func test_expirationString_full() {
        var subject = CardItemState()

        subject.expirationMonth = .custom(.jul)
        subject.expirationYear = "2025"
        XCTAssertEqual(subject.expirationString, "7/2025")

        subject.expirationMonth = .custom(.mar)
        subject.expirationYear = "2020"
        XCTAssertEqual(subject.expirationString, "3/2020")
    }

    /// `expirationString` returns the card's formatted expiration string when only the month is
    /// populated.
    func test_expirationString_onlyMonth() {
        var subject = CardItemState()

        subject.expirationMonth = .default
        XCTAssertEqual(subject.expirationString, "")

        subject.expirationMonth = .custom(.jan)
        XCTAssertEqual(subject.expirationString, "1")

        subject.expirationMonth = .custom(.sep)
        XCTAssertEqual(subject.expirationString, "9")
    }

    /// `expirationString` returns the card's formatted expiration string when only the year is
    /// populated.
    func test_expirationString_onlyYear() {
        var subject = CardItemState()

        subject.expirationYear = "2020"
        XCTAssertEqual(subject.expirationString, "2020")

        subject.expirationYear = "2025"
        XCTAssertEqual(subject.expirationString, "2025")
    }

    /// `isCardDetailsSectionEmpty` returns `false` if there are items to display in the card details section.
    func test_isCardDetailsSectionEmpty_false() {
        let subjectWithCardholderName = CardItemState(cardholderName: "John")
        XCTAssertFalse(subjectWithCardholderName.isCardDetailsSectionEmpty)

        let subjectWithCardNumber = CardItemState(cardNumber: "1234")
        XCTAssertFalse(subjectWithCardNumber.isCardDetailsSectionEmpty)

        let subjectWithExpirationString = CardItemState(expirationMonth: .custom(.may))
        XCTAssertFalse(subjectWithExpirationString.isCardDetailsSectionEmpty)

        let subjectWithCardSecurityCode = CardItemState(cardSecurityCode: "789")
        XCTAssertFalse(subjectWithCardSecurityCode.isCardDetailsSectionEmpty)
    }

    /// `isCardDetailsSectionEmpty` returns `true` if there are no items to display in the card details section.
    func test_isCardDetailsSectionEmpty_true() {
        let subject = CardItemState()
        XCTAssertTrue(subject.isCardDetailsSectionEmpty)
    }
}
