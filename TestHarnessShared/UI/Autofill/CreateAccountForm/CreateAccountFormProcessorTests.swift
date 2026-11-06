import BitwardenKit
import BitwardenKitMocks
import TestHelpers
import XCTest

@testable import TestHarnessShared

// MARK: - CreateAccountFormProcessorTests

/// Tests for `CreateAccountFormProcessor`.
///
@available(iOS 17, *)
class CreateAccountFormProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<RootRoute, Void>!
    var subject: CreateAccountFormProcessor!

    // MARK: Setup & Teardown

    @MainActor
    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        subject = CreateAccountFormProcessor(coordinator: coordinator.asAnyCoordinator())
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    // MARK: Initial State Tests

    /// Initial state has empty fields, no error, and zero account creation count.
    @MainActor
    func test_initialState() {
        XCTAssertEqual(subject.state.email, "")
        XCTAssertEqual(subject.state.password, "")
        XCTAssertEqual(subject.state.confirmPassword, "")
        XCTAssertNil(subject.state.errorMessage)
        XCTAssertEqual(subject.state.accountCreationCount, 0)
        XCTAssertFalse(subject.state.isAccountCreated)
    }

    // MARK: Action Tests

    /// `receive(.emailChanged)` updates the email in state.
    @MainActor
    func test_receive_emailChanged() {
        subject.receive(.emailChanged("user@example.com"))
        XCTAssertEqual(subject.state.email, "user@example.com")
    }

    /// `receive(.passwordChanged)` updates the password in state.
    @MainActor
    func test_receive_passwordChanged() {
        subject.receive(.passwordChanged("P@ssword123"))
        XCTAssertEqual(subject.state.password, "P@ssword123")
    }

    /// `receive(.passwordChanged)` clears any existing error message.
    @MainActor
    func test_receive_passwordChanged_clearsErrorMessage() async {
        subject.receive(.emailChanged("user@example.com"))
        subject.receive(.passwordChanged("P@ssword123"))
        subject.receive(.confirmPasswordChanged("Different1!"))
        await subject.perform(.createAccount)
        XCTAssertNotNil(subject.state.errorMessage)

        subject.receive(.passwordChanged("P@ssword123"))
        XCTAssertNil(subject.state.errorMessage)
    }

    /// `receive(.confirmPasswordChanged)` updates the confirm password in state.
    @MainActor
    func test_receive_confirmPasswordChanged() {
        subject.receive(.confirmPasswordChanged("P@ssword123"))
        XCTAssertEqual(subject.state.confirmPassword, "P@ssword123")
    }

    // MARK: Effect Tests

    /// `perform(.createAccount)` does nothing when any required field is empty.
    @MainActor
    func test_perform_createAccount_emptyFieldsDoNothing() async {
        subject.receive(.emailChanged("user@example.com"))
        subject.receive(.passwordChanged("P@ssword123"))
        // confirmPassword intentionally left empty
        await subject.perform(.createAccount)
        XCTAssertEqual(subject.state.accountCreationCount, 0)
        XCTAssertNil(subject.state.errorMessage)
    }

    /// `perform(.createAccount)` sets an error message when passwords do not match.
    @MainActor
    func test_perform_createAccount_passwordMismatchSetsError() async {
        subject.receive(.emailChanged("user@example.com"))
        subject.receive(.passwordChanged("P@ssword123"))
        subject.receive(.confirmPasswordChanged("Different1!"))
        await subject.perform(.createAccount)
        XCTAssertEqual(subject.state.errorMessage, Localizations.passwordsDoNotMatch)
        XCTAssertEqual(subject.state.accountCreationCount, 0)
    }

    /// `perform(.createAccount)` increments `accountCreationCount` and clears the error on success.
    @MainActor
    func test_perform_createAccount_successIncrementsCount() async {
        subject.receive(.emailChanged("user@example.com"))
        subject.receive(.passwordChanged("P@ssword123"))
        subject.receive(.confirmPasswordChanged("P@ssword123"))
        await subject.perform(.createAccount)
        XCTAssertEqual(subject.state.accountCreationCount, 1)
        XCTAssertTrue(subject.state.isAccountCreated)
        XCTAssertNil(subject.state.errorMessage)
    }

    /// `perform(.createAccount)` increments `accountCreationCount` on each successive submission,
    /// ensuring the view's `onChange` fires every time (not just on the first run).
    @MainActor
    func test_perform_createAccount_repeatedSubmissionsIncrementCountEachTime() async {
        subject.receive(.emailChanged("user@example.com"))
        subject.receive(.passwordChanged("P@ssword123"))
        subject.receive(.confirmPasswordChanged("P@ssword123"))

        await subject.perform(.createAccount)
        XCTAssertEqual(subject.state.accountCreationCount, 1)

        await subject.perform(.createAccount)
        XCTAssertEqual(subject.state.accountCreationCount, 2)

        await subject.perform(.createAccount)
        XCTAssertEqual(subject.state.accountCreationCount, 3)
    }

    /// `perform(.createAccount)` clears a previous mismatch error on a successful retry.
    @MainActor
    func test_perform_createAccount_successAfterMismatchClearsError() async {
        subject.receive(.emailChanged("user@example.com"))
        subject.receive(.passwordChanged("P@ssword123"))
        subject.receive(.confirmPasswordChanged("Different1!"))
        await subject.perform(.createAccount)
        XCTAssertNotNil(subject.state.errorMessage)

        subject.receive(.confirmPasswordChanged("P@ssword123"))
        await subject.perform(.createAccount)
        XCTAssertNil(subject.state.errorMessage)
        XCTAssertEqual(subject.state.accountCreationCount, 1)
    }
}
