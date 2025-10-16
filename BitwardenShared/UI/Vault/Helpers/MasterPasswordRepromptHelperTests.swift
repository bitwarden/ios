import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

@MainActor
class MasterPasswordRepromptHelperTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var subject: MasterPasswordRepromptHelper!
    var userVerificationHelper: MockUserVerificationHelper!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        userVerificationHelper = MockUserVerificationHelper()
        vaultRepository = MockVaultRepository()

        subject = DefaultMasterPasswordRepromptHelper(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                vaultRepository: vaultRepository,
            ),
            userVerificationHelper: userVerificationHelper,
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

        coordinator = nil
        errorReporter = nil
        subject = nil
        userVerificationHelper = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `repromptForMasterPasswordIfNeeded(cipherId:)` doesn't prompt the user and calls the
    /// completion closure if master password reprompt isn't required.
    func test_repromptForMasterPasswordIfNeeded_cipherId_noPasswordReprompt() async throws {
        vaultRepository.fetchCipherResult = .success(CipherView.fixture())

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherId: "1") {
            completionCalled = true
        }

        XCTAssertTrue(completionCalled)
        XCTAssertFalse(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherId:)` doesn't log an error if the password prompt is cancelled.
    func test_repromptForMasterPasswordIfNeeded_cipherId_passwordReprompt_cancelled() async throws {
        userVerificationHelper.verifyMasterPasswordResult = .failure(UserVerificationError.cancelled)
        vaultRepository.fetchCipherResult = .success(CipherView.fixture(reprompt: .password))

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherId: "1") {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
        XCTAssertTrue(coordinator.errorAlertsShown.isEmpty)
        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherId:)` logs an error and shows an alert if fetching
    /// the cipher fails.
    func test_repromptForMasterPasswordIfNeeded_cipherId_passwordReprompt_errorFetchCipher() async throws {
        vaultRepository.fetchCipherResult = .failure(BitwardenTestError.example)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherId: "1") {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertFalse(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherId:)` logs an error and shows an alert if
    /// validating the password fails.
    func test_repromptForMasterPasswordIfNeeded_cipherId_passwordReprompt_errorValidatePassword() async throws {
        userVerificationHelper.verifyMasterPasswordResult = .failure(BitwardenTestError.example)
        vaultRepository.fetchCipherResult = .success(CipherView.fixture(reprompt: .password))

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherId: "1") {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherId:)` logs an error and shows an alert if the
    /// cipher with the specified ID wasn't found.
    func test_repromptForMasterPasswordIfNeeded_cipherId_passwordReprompt_fetchCipherNil() async throws {
        vaultRepository.fetchCipherResult = .success(nil)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherId: "1") {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
        let error = try XCTUnwrap(errorReporter.errors.last as? NSError)
        XCTAssertIdentical(coordinator.errorAlertsShown.last as? NSError, error)
        XCTAssertEqual(error.userInfo["ErrorMessage"] as? String, "A cipher with the specified ID was not found.")
    }

    /// `repromptForMasterPasswordIfNeeded(cipherId:)` shows an alert if the entered password is invalid.
    func test_repromptForMasterPasswordIfNeeded_cipherId_passwordReprompt_invalidPassword() async throws {
        userVerificationHelper.verifyMasterPasswordResult = .success(.notVerified)
        vaultRepository.fetchCipherResult = .success(CipherView.fixture(reprompt: .password))

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherId: "1") {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherId:)` calls the completion closure if the
    /// master password reprompt was completed successfully.
    func test_repromptForMasterPasswordIfNeeded_cipherId_passwordReprompt_success() async throws {
        userVerificationHelper.verifyMasterPasswordResult = .success(.verified)
        vaultRepository.fetchCipherResult = .success(CipherView.fixture(reprompt: .password))

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherId: "1") {
            completionCalled = true
        }

        XCTAssertTrue(completionCalled)
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherListView:)` doesn't prompt the user and calls the
    /// completion closure if master password reprompt isn't required.
    func test_repromptForMasterPasswordIfNeeded_cipherListView_noPasswordReprompt() async throws {
        let cipherListView = CipherListView.fixture()

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherListView: cipherListView) {
            completionCalled = true
        }

        XCTAssertTrue(completionCalled)
        XCTAssertFalse(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherListView:)` doesn't log an error if the password prompt is cancelled.
    func test_repromptForMasterPasswordIfNeeded_cipherListView_passwordReprompt_cancelled() async throws {
        userVerificationHelper.verifyMasterPasswordResult = .failure(UserVerificationError.cancelled)

        let cipherListView = CipherListView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherListView: cipherListView) {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
        XCTAssertTrue(coordinator.errorAlertsShown.isEmpty)
        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherListView:)` logs an error and shows an alert if
    /// validating the password fails.
    func test_repromptForMasterPasswordIfNeeded_cipherListView_passwordReprompt_errorValidatePassword() async throws {
        userVerificationHelper.verifyMasterPasswordResult = .failure(BitwardenTestError.example)

        let cipherListView = CipherListView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherListView: cipherListView) {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherListView:)` shows an alert if the entered password is invalid.
    func test_repromptForMasterPasswordIfNeeded_cipherListView_passwordReprompt_invalidPassword() async throws {
        userVerificationHelper.verifyMasterPasswordResult = .success(.notVerified)

        let cipherListView = CipherListView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherListView: cipherListView) {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherListView:)` calls the completion closure if the
    /// master password reprompt was completed successfully.
    func test_repromptForMasterPasswordIfNeeded_cipherListView_passwordReprompt_success() async throws {
        userVerificationHelper.verifyMasterPasswordResult = .success(.verified)

        let cipherListView = CipherListView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherListView: cipherListView) {
            completionCalled = true
        }

        XCTAssertTrue(completionCalled)
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherView:)` doesn't prompt the user and calls the
    /// completion closure if master password reprompt isn't required.
    func test_repromptForMasterPasswordIfNeeded_cipherView_noPasswordReprompt() async throws {
        let cipherView = CipherView.fixture()

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
            completionCalled = true
        }

        XCTAssertTrue(completionCalled)
        XCTAssertFalse(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherView:)` doesn't log an error if the password prompt is cancelled.
    func test_repromptForMasterPasswordIfNeeded_cipherView_passwordReprompt_cancelled() async throws {
        userVerificationHelper.verifyMasterPasswordResult = .failure(UserVerificationError.cancelled)

        let cipherView = CipherView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
        XCTAssertTrue(coordinator.errorAlertsShown.isEmpty)
        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherView:)` logs an error and shows an alert if
    /// validating the password fails.
    func test_repromptForMasterPasswordIfNeeded_cipherView_passwordReprompt_errorValidatePassword() async throws {
        userVerificationHelper.verifyMasterPasswordResult = .failure(BitwardenTestError.example)

        let cipherView = CipherView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherView:)` shows an alert if the entered password is invalid.
    func test_repromptForMasterPasswordIfNeeded_cipherView_passwordReprompt_invalidPassword() async throws {
        userVerificationHelper.verifyMasterPasswordResult = .success(.notVerified)

        let cipherView = CipherView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherView:)` calls the completion closure if the
    /// master password reprompt was completed successfully.
    func test_repromptForMasterPasswordIfNeeded_cipherView_passwordReprompt_success() async throws {
        userVerificationHelper.verifyMasterPasswordResult = .success(.verified)

        let cipherView = CipherView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
            completionCalled = true
        }

        XCTAssertTrue(completionCalled)
        XCTAssertTrue(userVerificationHelper.verifyMasterPasswordCalled)
    }
}
