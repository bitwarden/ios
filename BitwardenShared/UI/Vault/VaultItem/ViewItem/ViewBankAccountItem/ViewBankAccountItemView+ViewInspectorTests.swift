// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
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

    /// The account number visibility toggle announces the field name and current state to VoiceOver.
    @MainActor
    func test_accountNumberVisibilityToggle_accessibilityLabel() throws {
        var state = populatedState()
        state.isAccountNumberVisible = false
        initSubject(state: state)
        _ = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.fieldValueIsNotVisibleTapToShow(Localizations.accountNumber),
        )

        state.isAccountNumberVisible = true
        initSubject(state: state)
        _ = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.fieldValueIsVisibleTapToHide(Localizations.accountNumber),
        )
    }

    /// The PIN visibility toggle announces the field name and current state to VoiceOver.
    @MainActor
    func test_pinVisibilityToggle_accessibilityLabel() throws {
        var state = populatedState()
        state.isPinVisible = false
        initSubject(state: state)
        _ = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.fieldValueIsNotVisibleTapToShow(Localizations.pin),
        )

        state.isPinVisible = true
        initSubject(state: state)
        _ = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.fieldValueIsVisibleTapToHide(Localizations.pin),
        )
    }

    /// The IBAN visibility toggle announces the field name and current state to VoiceOver.
    @MainActor
    func test_ibanVisibilityToggle_accessibilityLabel() throws {
        var state = populatedState()
        state.isIbanVisible = false
        initSubject(state: state)
        _ = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.fieldValueIsNotVisibleTapToShow(Localizations.iban),
        )

        state.isIbanVisible = true
        initSubject(state: state)
        _ = try subject.inspect().find(
            buttonWithAccessibilityLabel: Localizations.fieldValueIsVisibleTapToHide(Localizations.iban),
        )
    }

    /// The account number value announces its characters individually to VoiceOver when visible.
    @MainActor
    func test_accountNumber_accessibilityValue() throws {
        var state = populatedState()
        state.isAccountNumberVisible = true
        initSubject(state: state)
        let value = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "BankAccountNumberEntry",
        ).text().accessibilityValue().string()
        XCTAssertEqual(value, "1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6")
    }

    /// The PIN value announces its characters individually to VoiceOver when visible.
    @MainActor
    func test_pin_accessibilityValue() throws {
        var state = populatedState()
        state.isPinVisible = true
        initSubject(state: state)
        let value = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "BankAccountPinEntry",
        ).text().accessibilityValue().string()
        XCTAssertEqual(value, "1 2 3 4")
    }

    /// The IBAN value announces its characters individually to VoiceOver when visible.
    @MainActor
    func test_iban_accessibilityValue() throws {
        var state = populatedState()
        state.isIbanVisible = true
        initSubject(state: state)
        let value = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "BankAccountIbanEntry",
        ).text().accessibilityValue().string()
        XCTAssertEqual(value, "G B 3 3 B U K B 2 0 2 0 1 5 5 5 5 5 5 5 5 5")
    }

    /// The routing number value announces its characters individually to VoiceOver.
    @MainActor
    func test_routingNumber_accessibilityValue() throws {
        let value = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "BankAccountRoutingNumberEntry",
        ).accessibilityValue().string()
        XCTAssertEqual(value, "1 2 3 4 5 6 7 8 9 0")
    }

    /// The branch number value announces its characters individually to VoiceOver.
    @MainActor
    func test_branchNumber_accessibilityValue() throws {
        let value = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "BankAccountBranchNumberEntry",
        ).accessibilityValue().string()
        XCTAssertEqual(value, "1 0 0")
    }

    /// The SWIFT code value announces its characters individually to VoiceOver.
    @MainActor
    func test_swiftCode_accessibilityValue() throws {
        let value = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "BankAccountSwiftCodeEntry",
        ).accessibilityValue().string()
        XCTAssertEqual(value, "B O F A U S 3 N")
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
