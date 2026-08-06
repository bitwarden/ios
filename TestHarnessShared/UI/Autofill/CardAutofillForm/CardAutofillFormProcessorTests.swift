import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - CardAutofillFormProcessorTests

/// Tests for `CardAutofillFormProcessor`.
///
@available(iOS 17, *)
class CardAutofillFormProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<RootRoute, Void>!
    var subject: CardAutofillFormProcessor!

    // MARK: Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        subject = CardAutofillFormProcessor(coordinator: coordinator.asAnyCoordinator())
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    // MARK: Initial State Tests

    /// Initial state has empty string defaults for all card fields.
    @MainActor
    func test_initialState_allFieldsAreEmpty() {
        XCTAssertEqual(subject.state.cardholderName, "")
        XCTAssertEqual(subject.state.cardNumber, "")
        XCTAssertEqual(subject.state.expirationMonth, "")
        XCTAssertEqual(subject.state.expirationYear, "")
        XCTAssertEqual(subject.state.securityCode, "")
    }

    // MARK: Action Tests

    /// `receive(.cardholderNameChanged)` updates the cardholder name in state.
    @MainActor
    func test_receive_cardholderNameChanged() {
        subject.receive(.cardholderNameChanged("Jane Doe"))
        XCTAssertEqual(subject.state.cardholderName, "Jane Doe")
    }

    /// `receive(.cardholderNameChanged)` with an empty string clears the field.
    @MainActor
    func test_receive_cardholderNameChanged_emptyStringClearsField() {
        subject.receive(.cardholderNameChanged("Jane Doe"))
        subject.receive(.cardholderNameChanged(""))
        XCTAssertEqual(subject.state.cardholderName, "")
    }

    /// `receive(.cardholderNameChanged)` overwrites a previously set value.
    @MainActor
    func test_receive_cardholderNameChanged_overwritesPreviousValue() {
        subject.receive(.cardholderNameChanged("Jane Doe"))
        subject.receive(.cardholderNameChanged("John Smith"))
        XCTAssertEqual(subject.state.cardholderName, "John Smith")
    }

    // MARK: State Tests

    /// `hasAnyValue` is `false` when all fields are empty.
    @MainActor
    func test_hasAnyValue_allEmpty_isFalse() {
        XCTAssertFalse(subject.state.hasAnyValue)
    }

    /// `hasAnyValue` is `true` when only `cardholderName` is set.
    @MainActor
    func test_hasAnyValue_cardholderNameSet_isTrue() {
        subject.receive(.cardholderNameChanged("Jane Doe"))
        XCTAssertTrue(subject.state.hasAnyValue)
    }

    /// `hasAnyValue` is `true` when all fields have values.
    @MainActor
    func test_hasAnyValue_allFieldsSet_isTrue() {
        subject.receive(.cardholderNameChanged("Jane Doe"))
        subject.receive(.cardNumberChanged("4111111111111111"))
        subject.receive(.expirationMonthChanged("12"))
        subject.receive(.expirationYearChanged("2028"))
        subject.receive(.securityCodeChanged("123"))
        XCTAssertTrue(subject.state.hasAnyValue)
    }

    /// `hasAnyValue` is `false` after the only set field is cleared back to an empty string.
    @MainActor
    func test_hasAnyValue_onlyFieldClearedToEmpty_isFalse() {
        subject.receive(.cardholderNameChanged("Jane Doe"))
        subject.receive(.cardholderNameChanged(""))
        XCTAssertFalse(subject.state.hasAnyValue)
    }
}
