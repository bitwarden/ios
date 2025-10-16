import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// MARK: - TextAutofillHelperRepromptWrapperTests

@available(iOS 18.0, *)
class TextAutofillHelperRepromptWrapperTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var errorReporter: MockErrorReporter!
    var subject: TextAutofillHelperRepromptWrapper!
    var textAutofillHelper: MockTextAutofillHelper!
    var textAutofillHelperDelegate: MockTextAutofillHelperDelegate!
    var userVerificationHelper: MockUserVerificationHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        errorReporter = MockErrorReporter()
        userVerificationHelper = MockUserVerificationHelper()
        textAutofillHelper = MockTextAutofillHelper()
        textAutofillHelperDelegate = MockTextAutofillHelperDelegate()
        subject = TextAutofillHelperRepromptWrapper(
            authRepository: authRepository,
            errorReporter: errorReporter,
            textAutofillHelper: textAutofillHelper,
            userVerificationHelper: userVerificationHelper,
        )
        subject.setTextAutofillHelperDelegate(textAutofillHelperDelegate)
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        errorReporter = nil
        userVerificationHelper = nil
        subject = nil
        textAutofillHelper = nil
        textAutofillHelperDelegate = nil
    }

    // MARK: Tests

    /// `handleCipherForAutofill(cipherView:)` handles the cipher for autofill with the inner helper
    /// when cipher reprompt value is not password.
    func test_handleCipherForAutofill_noReprompt() async throws {
        try await subject.handleCipherForAutofill(cipherListView: .fixture(
            id: "1",
            reprompt: .none,
        ))
        XCTAssertEqual(
            textAutofillHelper.handleCipherForAutofillCalledWithCipher?.id,
            "1",
        )
        XCTAssertFalse(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `handleCipherForAutofill(cipherView:)` handles the cipher for autofill with the inner helper
    /// when cipher reprompt value is password but user doesn't have master password.
    func test_handleCipherForAutofill_cipherRepromptButNoMasterPassword() async throws {
        authRepository.hasMasterPasswordResult = .success(false)
        try await subject.handleCipherForAutofill(cipherListView: .fixture(
            id: "1",
            reprompt: .password,
        ))
        XCTAssertEqual(
            textAutofillHelper.handleCipherForAutofillCalledWithCipher?.id,
            "1",
        )
        XCTAssertFalse(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `handleCipherForAutofill(cipherView:)` handles the cipher for autofill with the inner helper
    /// when cipher reprompt value is password, user has master password and verifying master password
    /// results in `.verified`.
    func test_handleCipherForAutofill_cipherRepromptHasMasterPasswordAndVerified() async throws {
        authRepository.hasMasterPasswordResult = .success(true)
        userVerificationHelper.verifyMasterPasswordResult = .success(.verified)
        try await subject.handleCipherForAutofill(cipherListView: .fixture(
            id: "1",
            reprompt: .password,
        ))
        XCTAssertEqual(
            textAutofillHelper.handleCipherForAutofillCalledWithCipher?.id,
            "1",
        )
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `handleCipherForAutofill(cipherView:)` doesn't handle the cipher for autofill with the inner helper
    /// when cipher reprompt value is password, user has master password and verifying master password
    /// results in `.notVerified`.
    func test_handleCipherForAutofill_cipherRepromptHasMasterPasswordAndNotVerified() async throws {
        authRepository.hasMasterPasswordResult = .success(true)
        userVerificationHelper.verifyMasterPasswordResult = .success(.notVerified)
        try await subject.handleCipherForAutofill(cipherListView: .fixture(
            id: "1",
            reprompt: .password,
        ))
        XCTAssertNil(textAutofillHelper.handleCipherForAutofillCalledWithCipher?.id)
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `handleCipherForAutofill(cipherView:)` doesn't handle the cipher for autofill with the inner helper
    /// when cipher reprompt value is password, user has master password and verifying master password
    /// results in `.unableToPerform`.
    func test_handleCipherForAutofill_cipherRepromptHasMasterPasswordAndUnableToPerform() async throws {
        authRepository.hasMasterPasswordResult = .success(true)
        userVerificationHelper.verifyMasterPasswordResult = .success(.unableToPerform)
        try await subject.handleCipherForAutofill(cipherListView: .fixture(
            id: "1",
            reprompt: .password,
        ))
        XCTAssertNil(textAutofillHelper.handleCipherForAutofillCalledWithCipher?.id)
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `handleCipherForAutofill(cipherView:)` doesn't handle the cipher for autofill with the inner helper
    /// when cipher reprompt value is password, user has master password and verifying master password
    /// results in user cancelling.
    func test_handleCipherForAutofill_cipherRepromptHasMasterPasswordAndUserCancelled() async throws {
        authRepository.hasMasterPasswordResult = .success(true)
        userVerificationHelper.verifyMasterPasswordResult = .failure(UserVerificationError.cancelled)
        try await subject.handleCipherForAutofill(cipherListView: .fixture(
            id: "1",
            reprompt: .password,
        ))
        XCTAssertNil(textAutofillHelper.handleCipherForAutofillCalledWithCipher?.id)
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `handleCipherForAutofill(cipherView:)` doesn't handle the cipher for autofill with the inner helper
    /// when cipher reprompt value is password, user has master password and verifying master password
    /// throws error.
    func test_handleCipherForAutofill_cipherRepromptHasMasterPasswordAndVerifyingThrows() async throws {
        authRepository.hasMasterPasswordResult = .success(true)
        userVerificationHelper.verifyMasterPasswordResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.handleCipherForAutofill(cipherListView: .fixture(
                id: "1",
                reprompt: .password,
            ))
        }
        XCTAssertNil(textAutofillHelper.handleCipherForAutofillCalledWithCipher?.id)
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `handleCipherForAutofill(cipherView:)` doesn't handle the cipher for autofill with the inner helper
    /// when cipher reprompt value is password and checking if user has master password throws.
    func test_handleCipherForAutofill_cipherRepromptCheckHasMasterPasswordThrows() async throws {
        authRepository.hasMasterPasswordResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.handleCipherForAutofill(cipherListView: .fixture(
                id: "1",
                reprompt: .password,
            ))
        }
        XCTAssertNil(textAutofillHelper.handleCipherForAutofillCalledWithCipher?.id)
        XCTAssertFalse(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `setTextAutofillHelperDelegate(_:)` sets the delegate in the inner helper.
    func test_setTextAutofillHelperDelegate() {
        XCTAssertNotNil(textAutofillHelper.textAutofillHelperDelegate)
    }
}
