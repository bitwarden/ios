// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SwiftUI
import ViewInspector
import ViewInspectorTestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - AddEditItemViewBankAccountTests

class AddEditItemViewBankAccountTests: BitwardenTestCase {
    // MARK: Properties

    var processor: MockProcessor<AddEditItemState, AddEditItemAction, AddEditItemEffect>!
    var subject: AddEditItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(
            state: CipherItemState(
                hasPremium: true,
            ),
        )
        processor.state.ownershipOptions = [.personal(email: "user@bitwarden.com")]
        let store = Store(processor: processor)
        subject = AddEditItemView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Tests

    /// Updating the bank name field dispatches the `.bankAccountFieldChanged(.bankNameChanged())` action.
    @MainActor
    func test_bankAccount_bankNameTextField_updateValue() throws {
        processor.state.type = .bankAccount
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.bankName)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .bankAccountFieldChanged(.bankNameChanged("text")))
    }

    /// Updating the name on account field dispatches the `.bankAccountFieldChanged(.nameOnAccountChanged())` action.
    @MainActor
    func test_bankAccount_nameOnAccountTextField_updateValue() throws {
        processor.state.type = .bankAccount
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.nameOnAccount)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .bankAccountFieldChanged(.nameOnAccountChanged("text")))
    }

    /// Updating the account number field dispatches the
    /// `.bankAccountFieldChanged(.accountNumberChanged())` action.
    @MainActor
    func test_bankAccount_accountNumberTextField_updateValue() throws {
        processor.state.type = .bankAccount
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.accountNumber)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .bankAccountFieldChanged(.accountNumberChanged("text")))
    }

    /// Updating the routing number field dispatches the
    /// `.bankAccountFieldChanged(.routingNumberChanged())` action.
    @MainActor
    func test_bankAccount_routingNumberTextField_updateValue() throws {
        processor.state.type = .bankAccount
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.routingNumber)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .bankAccountFieldChanged(.routingNumberChanged("text")))
    }

    /// Updating the branch number field dispatches the
    /// `.bankAccountFieldChanged(.branchNumberChanged())` action.
    @MainActor
    func test_bankAccount_branchNumberTextField_updateValue() throws {
        processor.state.type = .bankAccount
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.branchNumber)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .bankAccountFieldChanged(.branchNumberChanged("text")))
    }

    /// Updating the PIN field dispatches the `.bankAccountFieldChanged(.pinChanged())` action.
    @MainActor
    func test_bankAccount_pinTextField_updateValue() throws {
        processor.state.type = .bankAccount
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.pin)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .bankAccountFieldChanged(.pinChanged("text")))
    }

    /// Updating the SWIFT code field dispatches the `.bankAccountFieldChanged(.swiftCodeChanged())` action.
    @MainActor
    func test_bankAccount_swiftCodeTextField_updateValue() throws {
        processor.state.type = .bankAccount
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.swiftCode)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .bankAccountFieldChanged(.swiftCodeChanged("text")))
    }

    /// Updating the IBAN field dispatches the `.bankAccountFieldChanged(.ibanChanged())` action.
    @MainActor
    func test_bankAccount_ibanTextField_updateValue() throws {
        processor.state.type = .bankAccount
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.iban)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(processor.dispatchedActions.last, .bankAccountFieldChanged(.ibanChanged("text")))
    }

    /// Updating the bank contact phone field dispatches the
    /// `.bankAccountFieldChanged(.bankContactPhoneChanged())` action.
    @MainActor
    func test_bankAccount_bankContactPhoneTextField_updateValue() throws {
        processor.state.type = .bankAccount
        let textField = try subject.inspect().find(bitwardenTextField: Localizations.bankContactPhone)
        try textField.inputBinding().wrappedValue = "text"
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .bankAccountFieldChanged(.bankContactPhoneChanged("text")),
        )
    }

    /// Tapping the account number visibility button dispatches the
    /// `.bankAccountFieldChanged(.toggleAccountNumberVisibilityChanged())` action when not visible.
    @MainActor
    func test_bankAccount_accountNumberVisibilityButton_tap_whenNotVisible() throws {
        processor.state.type = .bankAccount
        processor.state.bankAccountItemState.isAccountNumberVisible = false
        let button = try subject.inspect()
            .find(bitwardenTextField: Localizations.accountNumber)
            .find(buttonWithAccessibilityLabel: Localizations.passwordIsNotVisibleTapToShow)
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .bankAccountFieldChanged(.toggleAccountNumberVisibilityChanged(true)),
        )
    }

    /// Tapping the account number visibility button dispatches the
    /// `.bankAccountFieldChanged(.toggleAccountNumberVisibilityChanged())` action when visible.
    @MainActor
    func test_bankAccount_accountNumberVisibilityButton_tap_whenVisible() throws {
        processor.state.type = .bankAccount
        processor.state.bankAccountItemState.isAccountNumberVisible = true
        let button = try subject.inspect()
            .find(bitwardenTextField: Localizations.accountNumber)
            .find(buttonWithAccessibilityLabel: Localizations.passwordIsVisibleTapToHide)
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .bankAccountFieldChanged(.toggleAccountNumberVisibilityChanged(false)),
        )
    }

    /// Tapping the PIN visibility button dispatches the
    /// `.bankAccountFieldChanged(.togglePinVisibilityChanged())` action when not visible.
    @MainActor
    func test_bankAccount_pinVisibilityButton_tap_whenNotVisible() throws {
        processor.state.type = .bankAccount
        processor.state.bankAccountItemState.isPinVisible = false
        let button = try subject.inspect()
            .find(bitwardenTextField: Localizations.pin)
            .find(buttonWithAccessibilityLabel: Localizations.passwordIsNotVisibleTapToShow)
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .bankAccountFieldChanged(.togglePinVisibilityChanged(true)),
        )
    }

    /// Tapping the PIN visibility button dispatches the
    /// `.bankAccountFieldChanged(.togglePinVisibilityChanged())` action when visible.
    @MainActor
    func test_bankAccount_pinVisibilityButton_tap_whenVisible() throws {
        processor.state.type = .bankAccount
        processor.state.bankAccountItemState.isPinVisible = true
        let button = try subject.inspect()
            .find(bitwardenTextField: Localizations.pin)
            .find(buttonWithAccessibilityLabel: Localizations.passwordIsVisibleTapToHide)
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .bankAccountFieldChanged(.togglePinVisibilityChanged(false)),
        )
    }

    /// Tapping the IBAN visibility button dispatches the
    /// `.bankAccountFieldChanged(.toggleIbanVisibilityChanged())` action when not visible.
    @MainActor
    func test_bankAccount_ibanVisibilityButton_tap_whenNotVisible() throws {
        processor.state.type = .bankAccount
        processor.state.bankAccountItemState.isIbanVisible = false
        let button = try subject.inspect()
            .find(bitwardenTextField: Localizations.iban)
            .find(buttonWithAccessibilityLabel: Localizations.passwordIsNotVisibleTapToShow)
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .bankAccountFieldChanged(.toggleIbanVisibilityChanged(true)),
        )
    }

    /// Tapping the IBAN visibility button dispatches the
    /// `.bankAccountFieldChanged(.toggleIbanVisibilityChanged())` action when visible.
    @MainActor
    func test_bankAccount_ibanVisibilityButton_tap_whenVisible() throws {
        processor.state.type = .bankAccount
        processor.state.bankAccountItemState.isIbanVisible = true
        let button = try subject.inspect()
            .find(bitwardenTextField: Localizations.iban)
            .find(buttonWithAccessibilityLabel: Localizations.passwordIsVisibleTapToHide)
        try button.tap()
        XCTAssertEqual(
            processor.dispatchedActions.last,
            .bankAccountFieldChanged(.toggleIbanVisibilityChanged(false)),
        )
    }
}
