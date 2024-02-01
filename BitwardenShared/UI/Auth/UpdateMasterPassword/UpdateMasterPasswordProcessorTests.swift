import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - UpdateMasterPasswordProcessorTests

class UpdateMasterPasswordProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var httpClient: MockHTTPClient!
    var coordinator: MockCoordinator<AuthRoute, Void>!
    var subject: UpdateMasterPasswordProcessor!

    var errorReporter: MockErrorReporter!
    var policyService: MockPolicyService!
    var settingsRepository: MockSettingsRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        httpClient = MockHTTPClient()
        policyService = MockPolicyService()
        settingsRepository = MockSettingsRepository()

        let services = ServiceContainer.withMocks(
            errorReporter: errorReporter,
            httpClient: httpClient,
            policyService: policyService,
            settingsRepository: settingsRepository
        )
        let state = UpdateMasterPasswordState()
        subject = UpdateMasterPasswordProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services,
            state: state
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        httpClient = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform()` with `.appeared` fails to sync and move to main vault screen.
    func test_perform_appeared_fails() async throws {
        struct CryptoError: Error, Equatable {}
        policyService.getMasterPasswordPolicyOptionsResult = .failure(CryptoError())
        XCTAssertNil(subject.state.masterPasswordPolicy)
        await subject.perform(.appeared)
        XCTAssertNil(subject.state.masterPasswordPolicy)
        XCTAssertNil(coordinator.routes.last)
        XCTAssertEqual(errorReporter.errors.last as? CryptoError, CryptoError())
    }

    /// `perform()` with `.appeared` syncs vault and fetches `MasterPasswordPolicyOption`
    /// updates the state.
    func test_perform_appeared_success() async throws {
        policyService.getMasterPasswordPolicyOptionsResult = .success(
            MasterPasswordPolicyOptions(
                minComplexity: 3,
                minLength: 4,
                requireUpper: true,
                requireLower: true,
                requireNumbers: true,
                requireSpecial: true,
                enforceOnLogin: true
            )
        )
        XCTAssertNil(subject.state.masterPasswordPolicy)
        await subject.perform(.appeared)
        XCTAssertNotNil(subject.state.masterPasswordPolicy)
    }

    /// `perform()` with `.appeared` succeeds to sync but master password policy fails to load,
    /// and move to main vault screen.
    func test_perform_appeared_succeeds_policyNil() async throws {
        policyService.getMasterPasswordPolicyOptionsResult = .success(nil)
        XCTAssertNil(subject.state.masterPasswordPolicy)
        await subject.perform(.appeared)
        XCTAssertNil(subject.state.masterPasswordPolicy)
        XCTAssertEqual(coordinator.routes.last, .complete)
    }

    /// `perform()` with `.submitPressed` submits the request for updating the master password.
    func test_perform_submitPressed_success() async throws {
        // TODO: BIT-789
    }

    /// `receive(_:)` with `.currentMasterPasswordChanged` updates the state to reflect the changes.
    func test_receive_currentMasterPasswordChanged() {
        subject.state.currentMasterPassword = ""

        subject.receive(.currentMasterPasswordChanged("password"))
        XCTAssertEqual(subject.state.currentMasterPassword, "password")
    }

    /// `receive(_:)` with `.masterPasswordChanged` updates the state to reflect the changes.
    func test_receive_masterPasswordChanged() {
        subject.state.masterPassword = ""

        subject.receive(.masterPasswordChanged("password"))
        XCTAssertEqual(subject.state.masterPassword, "password")
    }

    /// `receive(_:)` with `.masterPasswordRetypeChanged` updates the state to reflect the changes.
    func test_receive_masterPasswordRetypeChanged() {
        subject.state.masterPasswordRetype = ""

        subject.receive(.masterPasswordRetypeChanged("password"))
        XCTAssertEqual(subject.state.masterPasswordRetype, "password")
    }

    /// `receive()` with `.masterPasswordHintChanged` and a value updates the state to reflect the
    /// changes.
    func test_receive_masterPasswordHintChanged() {
        subject.state.masterPasswordHint = ""
        subject.receive(.masterPasswordHintChanged("this is password hint"))

        XCTAssertEqual(subject.state.masterPasswordHint, "this is password hint")
    }

    /// `receive(_:)` with `.revealCurrentMasterPasswordFieldPressed` updates the state to reflect the changes.
    func test_receive_revealCurrentMasterPasswordFieldPressed() {
        subject.state.isCurrentMasterPasswordRevealed = false
        subject.receive(.revealCurrentMasterPasswordFieldPressed(true))
        XCTAssertTrue(subject.state.isCurrentMasterPasswordRevealed)

        subject.receive(.revealCurrentMasterPasswordFieldPressed(false))
        XCTAssertFalse(subject.state.isCurrentMasterPasswordRevealed)
    }

    /// `receive(_:)` with `.revealMasterPasswordFieldPressed` updates the state to reflect the changes.
    func test_receive_revealMasterPasswordFieldPressed() {
        subject.state.isMasterPasswordRevealed = false
        subject.receive(.revealMasterPasswordFieldPressed(true))
        XCTAssertTrue(subject.state.isMasterPasswordRevealed)

        subject.receive(.revealMasterPasswordFieldPressed(false))
        XCTAssertFalse(subject.state.isMasterPasswordRevealed)
    }

    /// `receive(_:)` with `.revealMasterPasswordRetypeFieldPressed` updates the state to reflect the changes.
    func test_receive_revealMasterPasswordRetypeFieldPressed() {
        subject.state.isMasterPasswordRetypeRevealed = false
        subject.receive(.revealMasterPasswordRetypeFieldPressed(true))
        XCTAssertTrue(subject.state.isMasterPasswordRetypeRevealed)

        subject.receive(.revealMasterPasswordRetypeFieldPressed(false))
        XCTAssertFalse(subject.state.isMasterPasswordRetypeRevealed)
    }
}
