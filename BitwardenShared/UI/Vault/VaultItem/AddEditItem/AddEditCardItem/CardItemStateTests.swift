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

    /// `formattedCardNumber` returns an empty string when the card number is empty.
    func test_formattedCardNumber_emptyNumber() {
        let subject = CardItemState()
        XCTAssertEqual(subject.formattedCardNumber, "")
    }

    /// `formattedCardNumber` auto-detects Amex from the number prefix when brand is `.default`.
    func test_formattedCardNumber_defaultBrand_detectsAmex() {
        var subject = CardItemState()
        subject.brand = .default
        subject.cardNumber = "378282246310005"
        XCTAssertEqual(subject.formattedCardNumber, "3782 822463 10005")
    }

    /// `formattedCardNumber` uses the Amex 4-6-5 grouping when the brand is explicitly set.
    func test_formattedCardNumber_explicitAmex() {
        var subject = CardItemState()
        subject.brand = .custom(.americanExpress)
        subject.cardNumber = "378282246310005"
        XCTAssertEqual(subject.formattedCardNumber, "3782 822463 10005")
    }

    /// `formattedCardNumber` uses the Visa 4-4-4-4 grouping when brand is explicitly Visa.
    func test_formattedCardNumber_explicitVisa() {
        var subject = CardItemState()
        subject.brand = .custom(.visa)
        subject.cardNumber = "4111111111111111"
        XCTAssertEqual(subject.formattedCardNumber, "4111 1111 1111 1111")
    }

    /// `formattedCardNumber` respects the explicitly selected brand even when the number
    /// prefix would suggest a different brand.
    func test_formattedCardNumber_explicitVisaBrandOverridesDetection() {
        var subject = CardItemState()
        subject.brand = .custom(.visa)
        subject.cardNumber = "3782822463"
        // Visa uses [4,4,4,4] blocks, not Amex [4,6,5]
        XCTAssertEqual(subject.formattedCardNumber, "3782 8224 63")
    }

    /// `formattedCardNumber` formats a partial number correctly with the auto-detected brand.
    func test_formattedCardNumber_partialNumber_defaultBrand() {
        var subject = CardItemState()
        subject.brand = .default
        subject.cardNumber = "411111"
        XCTAssertEqual(subject.formattedCardNumber, "4111 11")
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
