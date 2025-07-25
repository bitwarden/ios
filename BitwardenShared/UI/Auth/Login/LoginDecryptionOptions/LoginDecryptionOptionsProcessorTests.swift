import AuthenticationServices
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared

class LoginDecryptionOptionsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var accountAPIService: APIService!
    var authRepository: MockAuthRepository!
    var authService: MockAuthService!
    var client: MockHTTPClient!
    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var errorReporter: MockErrorReporter!
    var subject: LoginDecryptionOptionsProcessor!
    var stateService: MockStateService!
    var trustDeviceService: MockTrustDeviceService!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        accountAPIService = APIService(client: client)
        authRepository = MockAuthRepository()
        authService = MockAuthService()
        errorReporter = MockErrorReporter()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        trustDeviceService = MockTrustDeviceService()
        stateService = MockStateService()

        subject = LoginDecryptionOptionsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                authService: authService,
                errorReporter: errorReporter,
                stateService: stateService,
                trustDeviceService: trustDeviceService
            ),
            state: LoginDecryptionOptionsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        authService = nil
        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.approveWithMasterPasswordPressed` set should trust device and navigates.
    @MainActor
    func test_perform_approveWithMasterPassword_tapped() async throws {
        authRepository.activeAccount = .fixture()
        subject.state.isRememberDeviceToggleOn = true

        await subject.perform(.approveWithMasterPasswordPressed)

        XCTAssertEqual(trustDeviceService.shouldTrustDevice, true)
        XCTAssertEqual(coordinator.routes.last, .vaultUnlock(
            .fixture(),
            animated: true,
            attemptAutomaticBiometricUnlock: false,
            didSwitchAccountAutomatically: false
        ))
    }

    /// `perform(_:)` with `.approveWithOtherDevicePressed` set should trust device and navigates.
    @MainActor
    func test_perform_approveWithOtherDevice_tapped() async throws {
        subject.state.isRememberDeviceToggleOn = true
        subject.state.email = "example@bitwarden.com"

        await subject.perform(.approveWithOtherDevicePressed)

        XCTAssertEqual(trustDeviceService.shouldTrustDevice, true)
        XCTAssertEqual(coordinator.routes.last, .loginWithDevice(
            email: subject.state.email,
            authRequestType: AuthRequestType.authenticateAndUnlock,
            isAuthenticated: true
        ))
    }

    /// `perform(_:)` with `.continuePressed` creates new JIT user .
    @MainActor
    func test_perform_continue_tapped() async throws {
        subject.state.isRememberDeviceToggleOn = true
        subject.state.orgIdentifier = "Bitwarden"
        authRepository.createNewSsoUserResult = .success(())

        await subject.perform(.continuePressed)

        XCTAssertEqual(authRepository.createNewSsoUserOrgIdentifier, "Bitwarden")
        XCTAssertEqual(authRepository.createNewSsoUserRememberDevice, true)
        XCTAssertEqual(coordinator.events.last, .didCompleteAuth)
    }

    /// `perform(_:)` with `.loadLoginDecryptionOptions` load user decryption options.
    @MainActor
    func test_perform_loadLoginDecryptionOptions() async throws {
        authRepository.activeAccount = .fixtureWithTDE()

        await subject.perform(.loadLoginDecryptionOptions)

        XCTAssertEqual(subject.state.email, "user@bitwarden.com")
        XCTAssertTrue(subject.state.shouldShowAdminApprovalButton)
        XCTAssertTrue(subject.state.shouldShowApproveMasterPasswordButton)
        XCTAssertTrue(subject.state.shouldShowApproveWithOtherDeviceButton)
        XCTAssertFalse(subject.state.shouldShowContinueButton)
        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `perform(_:)` with `.loadLoginDecryptionOptions` load user decryption options.
    ///  has a pending admin request approved.
    @MainActor
    func test_perform_loadLoginDecryptionOptions_approvedPendingAdminRequest() async throws {
        authRepository.activeAccount = .fixtureWithTDE()
        authService.getPendingAdminLoginRequestResult = .success(.fixture())
        authService.getPendingLoginRequestResult = .success([.fixture(key: "KEY", requestApproved: true)])
        authRepository.unlockVaultFromLoginWithDeviceResult = .success(())

        await subject.perform(.loadLoginDecryptionOptions)

        XCTAssertEqual(subject.state.email, "user@bitwarden.com")
        XCTAssertTrue(subject.state.shouldShowAdminApprovalButton)
        XCTAssertTrue(subject.state.shouldShowApproveMasterPasswordButton)
        XCTAssertTrue(subject.state.shouldShowApproveWithOtherDeviceButton)
        XCTAssertFalse(subject.state.shouldShowContinueButton)
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.loginApproved))
        XCTAssertEqual(coordinator.events.last, .didCompleteAuth)
    }

    /// `perform(_:)` with `.requestAdminApprovalPressed` set should trust device and navigates.
    @MainActor
    func test_perform_requestAdminApproval_tapped() async throws {
        subject.state.isRememberDeviceToggleOn = true
        subject.state.email = "example@bitwarden.com"

        await subject.perform(.requestAdminApprovalPressed)

        XCTAssertEqual(trustDeviceService.shouldTrustDevice, true)
        XCTAssertEqual(coordinator.routes.last, .loginWithDevice(
            email: subject.state.email,
            authRequestType: AuthRequestType.adminApproval,
            isAuthenticated: true
        ))
    }

    /// `perform(_:)` with `.notYouPressed` sends action to logout the user.
    @MainActor
    func test_perform_notYou_tapped() async throws {
        await subject.perform(.notYouPressed)

        XCTAssertEqual(coordinator.events.last, .action(.logout(userId: nil, userInitiated: true)))
    }

    /// `receive(_:Bool)` with `.toggleRememberDevice` changes state value.
    @MainActor
    func test_receive_toggleRememberDevice() {
        subject.state.isRememberDeviceToggleOn = true
        subject.receive(.toggleRememberDevice(false))

        XCTAssertFalse(subject.state.isRememberDeviceToggleOn)
    }
}
