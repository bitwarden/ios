// swiftlint:disable:this file_name
import BitwardenKitMocks
import BitwardenResources
import SwiftUI
import ViewInspector
import XCTest

@testable import BitwardenKit
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

    /// The account number field asks VoiceOver to spell out its characters individually when
    /// visible.
    ///
    /// - Note: ViewInspector doesn't support inspecting `speechSpellsOutCharacters`, so this
    ///   verifies the flag is passed through to `PasswordText` rather than the final VoiceOver
    ///   announcement, which should be confirmed with on-device VoiceOver testing.
    @MainActor
    func test_accountNumber_spellsOutCharacters() throws {
        var state = populatedState()
        state.isAccountNumberVisible = true
        initSubject(state: state)
        let passwordText = try subject.inspect().find(PasswordText.self) { view in
            try view.actualView().password == "1234567890123456"
        }.actualView()
        XCTAssertTrue(passwordText.spellOutAccessibilityValue)
    }

    /// The PIN field asks VoiceOver to spell out its characters individually when visible.
    ///
    /// - Note: ViewInspector doesn't support inspecting `speechSpellsOutCharacters`, so this
    ///   verifies the flag is passed through to `PasswordText` rather than the final VoiceOver
    ///   announcement, which should be confirmed with on-device VoiceOver testing.
    @MainActor
    func test_pin_spellsOutCharacters() throws {
        var state = populatedState()
        state.isPinVisible = true
        initSubject(state: state)
        let passwordText = try subject.inspect().find(PasswordText.self) { view in
            try view.actualView().password == "1234"
        }.actualView()
        XCTAssertTrue(passwordText.spellOutAccessibilityValue)
    }

    /// The IBAN field asks VoiceOver to spell out its characters individually when visible.
    ///
    /// - Note: ViewInspector doesn't support inspecting `speechSpellsOutCharacters`, so this
    ///   verifies the flag is passed through to `PasswordText` rather than the final VoiceOver
    ///   announcement, which should be confirmed with on-device VoiceOver testing.
    @MainActor
    func test_iban_spellsOutCharacters() throws {
        var state = populatedState()
        state.isIbanVisible = true
        initSubject(state: state)
        let passwordText = try subject.inspect().find(PasswordText.self) { view in
            try view.actualView().password == "GB33BUKB20201555555555"
        }.actualView()
        XCTAssertTrue(passwordText.spellOutAccessibilityValue)
    }

    /// The routing number field asks VoiceOver to spell out its characters individually.
    ///
    /// - Note: ViewInspector doesn't support inspecting `speechSpellsOutCharacters`, so this
    ///   verifies the flag is passed through to `BitwardenTextValueField` rather than the final
    ///   VoiceOver announcement, which should be confirmed with on-device VoiceOver testing.
    @MainActor
    func test_routingNumber_spellsOutCharacters() throws {
        let field = try subject.inspect().find(
            BitwardenTextValueField<AccessoryButton>.self,
        ) { view in
            try view.actualView().value == "1234567890"
        }.actualView()
        XCTAssertTrue(field.spellOutAccessibilityValue)
    }

    /// The branch number field asks VoiceOver to spell out its characters individually.
    ///
    /// - Note: ViewInspector doesn't support inspecting `speechSpellsOutCharacters`, so this
    ///   verifies the flag is passed through to `BitwardenTextValueField` rather than the final
    ///   VoiceOver announcement, which should be confirmed with on-device VoiceOver testing.
    @MainActor
    func test_branchNumber_spellsOutCharacters() throws {
        let field = try subject.inspect().find(
            BitwardenTextValueField<AccessoryButton>.self,
        ) { view in
            try view.actualView().value == "100"
        }.actualView()
        XCTAssertTrue(field.spellOutAccessibilityValue)
    }

    /// The SWIFT code field asks VoiceOver to spell out its characters individually.
    ///
    /// - Note: ViewInspector doesn't support inspecting `speechSpellsOutCharacters`, so this
    ///   verifies the flag is passed through to `BitwardenTextValueField` rather than the final
    ///   VoiceOver announcement, which should be confirmed with on-device VoiceOver testing.
    @MainActor
    func test_swiftCode_spellsOutCharacters() throws {
        let field = try subject.inspect().find(
            BitwardenTextValueField<AccessoryButton>.self,
        ) { view in
            try view.actualView().value == "BOFAUS3N"
        }.actualView()
        XCTAssertTrue(field.spellOutAccessibilityValue)
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
