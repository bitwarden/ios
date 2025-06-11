import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

@MainActor
class MasterPasswordRepromptHelperTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var subject: MasterPasswordRepromptHelper!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()

        subject = DefaultMasterPasswordRepromptHelper(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                errorReporter: errorReporter,
                vaultRepository: vaultRepository
            )
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

        authRepository = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
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
    }

    /// `repromptForMasterPasswordIfNeeded(cipherId:)` logs an error and shows an alert if
    /// checking if the master password can be verified fails.
    func test_repromptForMasterPasswordIfNeeded_cipherId_passwordReprompt_errorCanVerifyMP() async throws {
        authRepository.canVerifyMasterPasswordResult = .failure(BitwardenTestError.example)
        vaultRepository.fetchCipherResult = .success(CipherView.fixture(reprompt: .password))

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherId: "1") {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
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
    }

    /// `repromptForMasterPasswordIfNeeded(cipherId:)` logs an error and shows an alert if
    /// validating the password fails.
    func test_repromptForMasterPasswordIfNeeded_cipherId_passwordReprompt_errorValidatePassword() async throws {
        authRepository.validatePasswordResult = .failure(BitwardenTestError.example)
        vaultRepository.fetchCipherResult = .success(CipherView.fixture(reprompt: .password))

        let cipherId = CipherListView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherId: "1") {
            completionCalled = true
        }

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt { _ in })
        try await repromptAlert.tapAction(title: Localizations.submit)

        XCTAssertFalse(completionCalled)
        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
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
        vaultRepository.fetchCipherResult = .success(CipherView.fixture(reprompt: .password))

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherId: "1") {
            completionCalled = true
        }

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt { _ in })

        authRepository.validatePasswordResult = .success(false)
        try await repromptAlert.tapAction(title: Localizations.submit)

        let invalidMasterPasswordAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(invalidMasterPasswordAlert, .defaultAlert(title: Localizations.invalidMasterPassword))

        XCTAssertFalse(completionCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherId:)` calls the completion closure if the
    /// master password reprompt was completed successfully.
    func test_repromptForMasterPasswordIfNeeded_cipherId_passwordReprompt_success() async throws {
        vaultRepository.fetchCipherResult = .success(CipherView.fixture(reprompt: .password))

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherId: "1") {
            completionCalled = true
        }

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt { _ in })

        authRepository.validatePasswordResult = .success(true)
        try await repromptAlert.tapAction(title: Localizations.submit)

        XCTAssertTrue(completionCalled)
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
    }

    /// `repromptForMasterPasswordIfNeeded(cipherListView:)` logs an error and shows an alert if
    /// checking if the master password can be verified fails.
    func test_repromptForMasterPasswordIfNeeded_cipherListView_passwordReprompt_errorCanVerifyMP() async throws {
        authRepository.canVerifyMasterPasswordResult = .failure(BitwardenTestError.example)

        let cipherListView = CipherListView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherListView: cipherListView) {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `repromptForMasterPasswordIfNeeded(cipherListView:)` logs an error and shows an alert if
    /// validating the password fails.
    func test_repromptForMasterPasswordIfNeeded_cipherListView_passwordReprompt_errorValidatePassword() async throws {
        authRepository.validatePasswordResult = .failure(BitwardenTestError.example)

        let cipherListView = CipherListView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherListView: cipherListView) {
            completionCalled = true
        }

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt { _ in })
        try await repromptAlert.tapAction(title: Localizations.submit)

        XCTAssertFalse(completionCalled)
        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `repromptForMasterPasswordIfNeeded(cipherListView:)` shows an alert if the entered password is invalid.
    func test_repromptForMasterPasswordIfNeeded_cipherListView_passwordReprompt_invalidPassword() async throws {
        let cipherListView = CipherListView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherListView: cipherListView) {
            completionCalled = true
        }

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt { _ in })

        authRepository.validatePasswordResult = .success(false)
        try await repromptAlert.tapAction(title: Localizations.submit)

        let invalidMasterPasswordAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(invalidMasterPasswordAlert, .defaultAlert(title: Localizations.invalidMasterPassword))

        XCTAssertFalse(completionCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherListView:)` calls the completion closure if the
    /// master password reprompt was completed successfully.
    func test_repromptForMasterPasswordIfNeeded_cipherListView_passwordReprompt_success() async throws {
        let cipherListView = CipherListView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherListView: cipherListView) {
            completionCalled = true
        }

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt { _ in })

        authRepository.validatePasswordResult = .success(true)
        try await repromptAlert.tapAction(title: Localizations.submit)

        XCTAssertTrue(completionCalled)
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
    }

    /// `repromptForMasterPasswordIfNeeded(cipherView:)` logs an error and shows an alert if
    /// checking if the master password can be verified fails.
    func test_repromptForMasterPasswordIfNeeded_cipherView_passwordReprompt_errorCanVerifyMP() async throws {
        authRepository.canVerifyMasterPasswordResult = .failure(BitwardenTestError.example)

        let cipherView = CipherView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
            completionCalled = true
        }

        XCTAssertFalse(completionCalled)
        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `repromptForMasterPasswordIfNeeded(cipherView:)` logs an error and shows an alert if
    /// validating the password fails.
    func test_repromptForMasterPasswordIfNeeded_cipherView_passwordReprompt_errorValidatePassword() async throws {
        authRepository.validatePasswordResult = .failure(BitwardenTestError.example)

        let cipherView = CipherView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
            completionCalled = true
        }

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt { _ in })
        try await repromptAlert.tapAction(title: Localizations.submit)

        XCTAssertFalse(completionCalled)
        XCTAssertEqual(coordinator.errorAlertsShown.last as? BitwardenTestError, .example)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `repromptForMasterPasswordIfNeeded(cipherView:)` shows an alert if the entered password is invalid.
    func test_repromptForMasterPasswordIfNeeded_cipherView_passwordReprompt_invalidPassword() async throws {
        let cipherView = CipherView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
            completionCalled = true
        }

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt { _ in })

        authRepository.validatePasswordResult = .success(false)
        try await repromptAlert.tapAction(title: Localizations.submit)

        let invalidMasterPasswordAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(invalidMasterPasswordAlert, .defaultAlert(title: Localizations.invalidMasterPassword))

        XCTAssertFalse(completionCalled)
    }

    /// `repromptForMasterPasswordIfNeeded(cipherView:)` calls the completion closure if the
    /// master password reprompt was completed successfully.
    func test_repromptForMasterPasswordIfNeeded_cipherView_passwordReprompt_success() async throws {
        let cipherView = CipherView.fixture(reprompt: .password)

        var completionCalled = false
        await subject.repromptForMasterPasswordIfNeeded(cipherView: cipherView) {
            completionCalled = true
        }

        let repromptAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(repromptAlert, .masterPasswordPrompt { _ in })

        authRepository.validatePasswordResult = .success(true)
        try await repromptAlert.tapAction(title: Localizations.submit)

        XCTAssertTrue(completionCalled)
    }
}
