import XCTest

@testable import BitwardenShared

class BankAccountItemStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `isBankAccountDetailsSectionEmpty` returns `true` when no fields are populated.
    func test_isBankAccountDetailsSectionEmpty_true() {
        let subject = BankAccountItemState()
        XCTAssertTrue(subject.isBankAccountDetailsSectionEmpty)
    }

    /// `isBankAccountDetailsSectionEmpty` returns `false` when any scalar text field is populated.
    func test_isBankAccountDetailsSectionEmpty_false_whenBankNameSet() {
        var subject = BankAccountItemState()
        subject.bankName = "Bitwarden Bank"
        XCTAssertFalse(subject.isBankAccountDetailsSectionEmpty)
    }

    /// `isBankAccountDetailsSectionEmpty` returns `false` when `accountType` is a custom case.
    func test_isBankAccountDetailsSectionEmpty_false_whenAccountTypeCustom() {
        var subject = BankAccountItemState()
        subject.accountType = .custom(.savings)
        XCTAssertFalse(subject.isBankAccountDetailsSectionEmpty)
    }

    /// `isBankAccountDetailsSectionEmpty` returns `false` when any hidden field has a value.
    func test_isBankAccountDetailsSectionEmpty_false_whenPinSet() {
        var subject = BankAccountItemState()
        subject.pin = "1234"
        XCTAssertFalse(subject.isBankAccountDetailsSectionEmpty)
    }

    /// `apiModel` serializes populated fields verbatim.
    func test_apiModel_populatesAllFields() {
        var subject = BankAccountItemState()
        subject.accountNumber = "1234567890"
        subject.accountType = .custom(.checking)
        subject.bankName = "Bitwarden Bank"
        subject.bankPhone = "555-0100"
        subject.branchNumber = "100"
        subject.iban = "GB82WEST12345698765432"
        subject.nameOnAccount = "Bitwarden User"
        subject.pin = "1234"
        subject.routingNumber = "011000015"
        subject.swiftCode = "BTCBUS33"

        let model = subject.apiModel
        XCTAssertEqual(model.accountNumber, "1234567890")
        XCTAssertEqual(model.accountType, .checking)
        XCTAssertEqual(model.bankName, "Bitwarden Bank")
        XCTAssertEqual(model.bankPhone, "555-0100")
        XCTAssertEqual(model.branchNumber, "100")
        XCTAssertEqual(model.iban, "GB82WEST12345698765432")
        XCTAssertEqual(model.nameOnAccount, "Bitwarden User")
        XCTAssertEqual(model.pin, "1234")
        XCTAssertEqual(model.routingNumber, "011000015")
        XCTAssertEqual(model.swiftCode, "BTCBUS33")
    }

    /// `apiModel` maps empty strings to `nil` so the wire representation stays minimal.
    func test_apiModel_emptyStringsBecomeNil() {
        let subject = BankAccountItemState()
        let model = subject.apiModel
        XCTAssertNil(model.accountNumber)
        XCTAssertNil(model.accountType)
        XCTAssertNil(model.bankName)
        XCTAssertNil(model.bankPhone)
        XCTAssertNil(model.branchNumber)
        XCTAssertNil(model.iban)
        XCTAssertNil(model.nameOnAccount)
        XCTAssertNil(model.pin)
        XCTAssertNil(model.routingNumber)
        XCTAssertNil(model.swiftCode)
    }

    /// `fromAPIModel(_:)` returns an empty state when `nil` is passed.
    func test_fromAPIModel_nil_returnsEmptyState() {
        let subject = BankAccountItemState.fromAPIModel(nil)
        XCTAssertEqual(subject, BankAccountItemState())
    }

    /// `fromAPIModel(_:)` populates scalar and enum fields from the API payload.
    func test_fromAPIModel_populatesState() {
        let model = CipherBankAccountModel(
            accountNumber: "1234567890",
            accountType: .savings,
            bankName: "Bitwarden Bank",
            bankPhone: "555-0100",
            branchNumber: "100",
            iban: "GB82WEST12345698765432",
            nameOnAccount: "Bitwarden User",
            pin: "1234",
            routingNumber: "011000015",
            swiftCode: "BTCBUS33",
        )
        let subject = BankAccountItemState.fromAPIModel(model)
        XCTAssertEqual(subject.accountNumber, "1234567890")
        XCTAssertEqual(subject.accountType, .custom(.savings))
        XCTAssertEqual(subject.bankName, "Bitwarden Bank")
        XCTAssertEqual(subject.bankPhone, "555-0100")
        XCTAssertEqual(subject.branchNumber, "100")
        XCTAssertEqual(subject.iban, "GB82WEST12345698765432")
        XCTAssertEqual(subject.nameOnAccount, "Bitwarden User")
        XCTAssertEqual(subject.pin, "1234")
        XCTAssertEqual(subject.routingNumber, "011000015")
        XCTAssertEqual(subject.swiftCode, "BTCBUS33")
    }

    /// Visibility flags default to hidden.
    func test_visibilityFlags_defaultToHidden() {
        let subject = BankAccountItemState()
        XCTAssertFalse(subject.isAccountNumberVisible)
        XCTAssertFalse(subject.isPinVisible)
    }
}
