import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - Fido2UserVerificationMediatorTests

class Fido2UserVerificationMediatorTests: BitwardenTestCase {
    // MARK: Types

    typealias VerifyFunction = () async throws -> UserVerificationResult

    // MARK: Properties

    var authRepository: MockAuthRepository!
    var errorReporter: MockErrorReporter!
    var fido2UserVerificationMediatorDelegate: MockFido2UserVerificationMediatorDelegate!
    var localAuthService: MockLocalAuthService!
    var stateService: MockStateService!
    var subject: Fido2UserVerificationMediator!
    var userVerificationHelper: MockUserVerificationHelper!
    var userVerificationRunner: MockUserVerificationRunner!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        fido2UserVerificationMediatorDelegate = MockFido2UserVerificationMediatorDelegate()
        authRepository = MockAuthRepository()
        errorReporter = MockErrorReporter()
        localAuthService = MockLocalAuthService()
        stateService = MockStateService()
        let services = ServiceContainer.withMocks(
            authRepository: authRepository,
            errorReporter: errorReporter,
            localAuthService: localAuthService,
            stateService: stateService
        )
        userVerificationHelper = MockUserVerificationHelper()
        userVerificationRunner = MockUserVerificationRunner()
        subject = DefaultFido2UserVerificationMediator(
            fido2UserVerificationMediatorDelegate: fido2UserVerificationMediatorDelegate,
            services: services,
            userVerificationHelper: userVerificationHelper,
            userVerificationRunner: userVerificationRunner
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        errorReporter = nil
        fido2UserVerificationMediatorDelegate = nil
        localAuthService = nil
        stateService = nil
        userVerificationHelper = nil
        userVerificationRunner = nil
        subject = nil
    }

    // MARK: Tests

    /// `checkUser(userVerificationPreference:,credential:)`  with each preference,
    /// reprompt enabled and reprompt verified.
    func test_checkUser_anyPreference_verified_when_reprompt_and_reprompt_verified() async throws {
        try await checkUser_verified_when_reprompt_and_reprompt_verified(.discouraged)
        try await checkUser_verified_when_reprompt_and_reprompt_verified(.preferred)
        try await checkUser_verified_when_reprompt_and_reprompt_verified(.required)
    }

    /// `checkUser(userVerificationPreference:,credential:)`  with each preference,
    /// reprompt enabled and reprompt not verified.
    func test_checkUser_anyPreference_not_verified_when_reprompt_and_reprompt_not_verified() async throws {
        try await checkUser_not_verified_when_reprompt_and_reprompt_not_verified(.discouraged)
        try await checkUser_not_verified_when_reprompt_and_reprompt_not_verified(.preferred)
        try await checkUser_not_verified_when_reprompt_and_reprompt_not_verified(.required)
    }

    /// `checkUser(userVerificationPreference:,credential:)`  with each preference,
    /// reprompt enabled and reprompt throws.
    func test_checkUser_anyPreference_throws_when_reprompt_and_reprompt_throws() async throws {
        try await checkUser_throws_when_reprompt_and_reprompt_throws(.discouraged)
        try await checkUser_throws_when_reprompt_and_reprompt_throws(.preferred)
        try await checkUser_throws_when_reprompt_and_reprompt_throws(.required)
    }

    /// `checkUser(userVerificationPreference:,credential:)`  with preference discouraged,
    /// reprompt none.
    func test_checkUser_discouraged_not_verified_when_no_reprompt() async throws {
        let cipher = CipherView.fixture()
        let result = try await subject.checkUser(userVerificationPreference: .discouraged, credential: cipher)

        XCTAssertEqual(result, CheckUserResult(userPresent: true, userVerified: false))
    }

    /// `checkUser(userVerificationPreference:,credential:)`  with preference preferred,
    /// reprompt none and verified device local auth.
    func test_checkUser_preferred_verified_device_auth() async throws {
        userVerificationHelper.verifyDeviceLocalAuthResult = .success(.verified)

        let cipher = CipherView.fixture()
        let result = try await subject.checkUser(userVerificationPreference: .preferred, credential: cipher)

        XCTAssertEqual(result, CheckUserResult(userPresent: true, userVerified: true))
        XCTAssertEqual(
            userVerificationHelper.verifyDeviceLocalAuthBecauseValue,
            Localizations.userVerificationForPasskey
        )
    }

    /// `checkUser(userVerificationPreference:,credential:)`  with preference preferred,
    /// reprompt none and not verified device local auth.
    func test_checkUser_preferred_not_verified_device_auth_not_verified() async throws {
        userVerificationHelper.verifyDeviceLocalAuthResult = .success(.notVerified)

        let cipher = CipherView.fixture()
        let result = try await subject.checkUser(userVerificationPreference: .preferred, credential: cipher)

        XCTAssertEqual(result, CheckUserResult(userPresent: true, userVerified: false))
        XCTAssertEqual(
            userVerificationHelper.verifyDeviceLocalAuthBecauseValue,
            Localizations.userVerificationForPasskey
        )
    }

    /// `checkUser(userVerificationPreference:,credential:)`  with preference required,
    /// reprompt none and verified flow.
    func test_checkUser_required_verified_when_verified_flow() async throws {
        userVerificationRunner.verifyInQueueResult = .success(.verified)

        setup_checkUser_onVerifyFunctions()

        let cipher = CipherView.fixture()
        let result = try await subject.checkUser(userVerificationPreference: .required, credential: cipher)

        XCTAssertTrue(userVerificationRunner.verifyInQueueCalled)
        XCTAssertTrue(userVerificationRunner.verifyWithAttemptsTimesCalled == 2)
        XCTAssertEqual(result, CheckUserResult(userPresent: true, userVerified: true))
        XCTAssertEqual(
            userVerificationHelper.verifyDeviceLocalAuthBecauseValue,
            Localizations.userVerificationForPasskey
        )
    }

    /// `checkUser(userVerificationPreference:,credential:)`  with preference required,
    /// reprompt none and not verified flow.
    func test_checkUser_required_verified_when_not_verified_flow() async throws {
        userVerificationRunner.verifyInQueueResult = .success(.notVerified)

        setup_checkUser_onVerifyFunctions()

        let cipher = CipherView.fixture()
        let result = try await subject.checkUser(userVerificationPreference: .required, credential: cipher)

        XCTAssertTrue(userVerificationRunner.verifyInQueueCalled)
        XCTAssertTrue(userVerificationRunner.verifyWithAttemptsTimesCalled == 2)
        XCTAssertEqual(result, CheckUserResult(userPresent: true, userVerified: false))
        XCTAssertEqual(
            userVerificationHelper.verifyDeviceLocalAuthBecauseValue,
            Localizations.userVerificationForPasskey
        )
    }

    /// `checkUser(userVerificationPreference:,credential:)`  with preference required,
    /// reprompt none and cant perform device local auth, pin nor master passwrod verifications.
    func test_checkUser_required_verified_when_cant_perform_flow() async throws {
        userVerificationRunner.verifyInQueueResult = .success(.cantPerform)

        setup_checkUser_onVerifyFunctions()

        let cipher = CipherView.fixture()
        let result = try await subject.checkUser(userVerificationPreference: .required, credential: cipher)

        XCTAssertTrue(userVerificationRunner.verifyInQueueCalled)
        XCTAssertTrue(userVerificationRunner.verifyWithAttemptsTimesCalled == 2)
        XCTAssertEqual(result, CheckUserResult(userPresent: true, userVerified: true))
        XCTAssertTrue(fido2UserVerificationMediatorDelegate.setupPinCalled)
        XCTAssertEqual(
            userVerificationHelper.verifyDeviceLocalAuthBecauseValue,
            Localizations.userVerificationForPasskey
        )
    }

    // MARK: Private

    private func checkUser_verified_when_reprompt_and_reprompt_verified(
        _ userVerificationPreference: Verification
    ) async throws {
        authRepository.canVerifyMasterPasswordResult = .success(true)
        userVerificationHelper.verifyMasterPasswordResult = .success(.verified)

        let cipher = CipherView.fixture(reprompt: .password)
        let result = try await subject.checkUser(
            userVerificationPreference: userVerificationPreference,
            credential: cipher
        )

        XCTAssertEqual(
            result,
            CheckUserResult(userPresent: true, userVerified: true),
            "Failed for preference \(userVerificationPreference)"
        )
    }

    private func checkUser_not_verified_when_reprompt_and_reprompt_not_verified(
        _ userVerificationPreference: Verification
    ) async throws {
        authRepository.canVerifyMasterPasswordResult = .success(true)
        userVerificationHelper.verifyMasterPasswordResult = .success(.notVerified)

        let cipher = CipherView.fixture(reprompt: .password)
        let result = try await subject.checkUser(
            userVerificationPreference: userVerificationPreference,
            credential: cipher
        )

        XCTAssertEqual(
            result,
            CheckUserResult(userPresent: true, userVerified: false),
            "Failed for preference \(userVerificationPreference)"
        )
    }

    private func checkUser_throws_when_reprompt_and_reprompt_throws(
        _ userVerificationPreference: Verification
    ) async throws {
        authRepository.canVerifyMasterPasswordResult = .success(true)
        userVerificationHelper.verifyMasterPasswordResult = .failure(BitwardenTestError.example)

        let cipher = CipherView.fixture(reprompt: .password)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.checkUser(
                userVerificationPreference: userVerificationPreference,
                credential: cipher
            )
        }
    }

    private func setup_checkUser_onVerifyFunctions() {
        userVerificationRunner.onVerifyInQueueFunctionCalled = { index in
            switch index {
            case 0:
                XCTAssertTrue(self.userVerificationHelper.verifyDeviceLocalAuthCalled)
                XCTAssertFalse(self.userVerificationHelper.verifyPinCalled)
                XCTAssertFalse(self.userVerificationHelper.verifyMasterPasswordCalled)
            case 1:
                XCTAssertTrue(self.userVerificationHelper.verifyDeviceLocalAuthCalled)
                XCTAssertTrue(self.userVerificationHelper.verifyPinCalled)
                XCTAssertFalse(self.userVerificationHelper.verifyMasterPasswordCalled)
            case 2:
                XCTAssertTrue(self.userVerificationHelper.verifyDeviceLocalAuthCalled)
                XCTAssertTrue(self.userVerificationHelper.verifyPinCalled)
                XCTAssertTrue(self.userVerificationHelper.verifyMasterPasswordCalled)
            default:
                XCTFail("Failed because there are more verify functions than expected")
            }
        }

        userVerificationRunner.onverifyWithAttemptsFunctionCalled = { timesCalled in
            switch timesCalled {
            case 1:
                XCTAssertTrue(self.userVerificationHelper.verifyPinCalled)
                XCTAssertFalse(self.userVerificationHelper.verifyMasterPasswordCalled)
            case 2:
                XCTAssertTrue(self.userVerificationHelper.verifyPinCalled)
                XCTAssertTrue(self.userVerificationHelper.verifyMasterPasswordCalled)
            default:
                XCTFail("Failed because verify with attempts was called more than expected")
            }
        }
    }
}

class MockFido2UserVerificationMediatorDelegate: // swiftlint:disable:this type_name
    MockUserVerificationHelperDelegate,
    Fido2UserVerificationMediatorDelegate {
    var setupPinCalled = false

    func setupPin() async throws {
        setupPinCalled = true
    }
}
