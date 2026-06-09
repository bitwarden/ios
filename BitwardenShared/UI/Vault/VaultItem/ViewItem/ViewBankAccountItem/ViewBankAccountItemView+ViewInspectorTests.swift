// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenShared

class ViewBankAccountItemViewTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<BankAccountItemState, ViewItemAction, Void>!
    var subject: ViewBankAccountItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        initSubject(state: populatedState())
    }

    override func tearDown() {
        super.tearDown()

        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Tapping the copy account number button dispatches the copy action.
    @MainActor
    func test_copyAccountNumberButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "BankAccountCopyNumberButton",
        ).button()
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .copyPressed(value: "1234567890123456", field: .accountNumber),
        )
    }

    /// Tapping the copy routing number button dispatches the copy action.
    @MainActor
    func test_copyRoutingNumberButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "BankAccountCopyRoutingNumberButton",
        ).button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "1234567890", field: .routingNumber))
    }

    /// Tapping the copy PIN button dispatches the copy action.
    @MainActor
    func test_copyPinButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "BankAccountCopyPinButton",
        ).button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "1234", field: .pin))
    }

    /// Tapping the copy SWIFT code button dispatches the copy action.
    @MainActor
    func test_copySwiftCodeButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "BankAccountCopySwiftCodeButton",
        ).button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "BOFAUS3N", field: .swiftCode))
    }

    /// Tapping the copy branch number button dispatches the copy action.
    @MainActor
    func test_copyBranchNumberButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "BankAccountCopyBranchNumberButton",
        ).button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "100", field: .branchNumber))
    }

    /// Tapping the copy bank contact phone button dispatches the copy action.
    @MainActor
    func test_copyContactPhoneButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "BankAccountCopyContactPhoneButton",
        ).button()
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .copyPressed(value: "123-456-7890", field: .bankContactPhone))
    }

    /// Tapping the copy name on account button dispatches the copy action.
    @MainActor
    func test_copyNameOnAccountButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "BankAccountCopyNameOnAccountButton",
        ).button()
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .copyPressed(value: "Personal Checking", field: .nameOnAccount),
        )
    }

    /// Tapping the copy IBAN button dispatches the copy action.
    @MainActor
    func test_copyIbanButton_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "BankAccountCopyIbanButton",
        ).button()
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .copyPressed(value: "GB33BUKB20201555555555", field: .iban),
        )
    }

    /// Tapping the account number visibility toggle dispatches the toggle action.
    @MainActor
    func test_accountNumberVisibilityToggle_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "ShowBankAccountNumberButton",
        ).button()
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .bankAccountItemAction(.toggleAccountNumberVisibilityChanged(true)),
        )
    }

    /// Tapping the PIN visibility toggle dispatches the toggle action.
    @MainActor
    func test_pinVisibilityToggle_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "ShowBankAccountPinButton",
        ).button()
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .bankAccountItemAction(.togglePinVisibilityChanged(true)),
        )
    }

    /// Tapping the IBAN visibility toggle dispatches the toggle action.
    @MainActor
    func test_ibanVisibilityToggle_pressed() throws {
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "ShowBankAccountIbanButton",
        ).button()
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .bankAccountItemAction(.toggleIbanVisibilityChanged(true)),
        )
    }

    /// An empty state renders no fields, so the copy and reveal buttons are absent.
    @MainActor
    func test_emptyState_hidesFields() throws {
        initSubject(state: BankAccountItemState())
        XCTAssertThrowsError(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "BankAccountCopyNumberButton").button(),
        )
        XCTAssertThrowsError(
            try subject.inspect().find(viewWithAccessibilityIdentifier: "ShowBankAccountNumberButton").button(),
        )
    }

    /// `isBankAccountDetailsSectionEmpty` is `true` when every field is empty and no account type is selected.
    func test_isBankAccountDetailsSectionEmpty_empty() {
        XCTAssertTrue(BankAccountItemState().isBankAccountDetailsSectionEmpty)
    }

    /// `isBankAccountDetailsSectionEmpty` is `false` when any string field has a value.
    func test_isBankAccountDetailsSectionEmpty_populatedField() {
        var state = BankAccountItemState()
        state.bankName = "Bank of America"
        XCTAssertFalse(state.isBankAccountDetailsSectionEmpty)
    }

    /// `isBankAccountDetailsSectionEmpty` is `false` when only an account type is selected and all fields are empty.
    func test_isBankAccountDetailsSectionEmpty_accountTypeOnly() {
        var state = BankAccountItemState()
        state.accountType = .custom(.checking)
        XCTAssertFalse(state.isBankAccountDetailsSectionEmpty)
    }

    // MARK: Private

    /// Initializes the subject with the given state.
    ///
    /// - Parameter state: The bank account state to render.
    ///
    @MainActor
    func initSubject(state: BankAccountItemState) {
        processor = MockProcessor(state: state)
        subject = ViewBankAccountItemView(store: Store(processor: processor))
    }

    /// A fully populated bank account state.
    private func populatedState() -> BankAccountItemState {
        var state = BankAccountItemState()
        state.accountNumber = "1234567890123456"
        state.accountType = .custom(.checking)
        state.bankContactPhone = "123-456-7890"
        state.bankName = "Bank of America"
        state.branchNumber = "100"
        state.iban = "GB33BUKB20201555555555"
        state.nameOnAccount = "Personal Checking"
        state.pin = "1234"
        state.routingNumber = "1234567890"
        state.swiftCode = "BOFAUS3N"
        return state
    }
}
