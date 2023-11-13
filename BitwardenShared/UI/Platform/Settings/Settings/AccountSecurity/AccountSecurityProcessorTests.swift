import XCTest

@testable import BitwardenShared

class AccountSecurityProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var settingsRepository: MockSettingsRepository!
    var subject: AccountSecurityProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        settingsRepository = MockSettingsRepository()
        subject = AccountSecurityProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(settingsRepository: settingsRepository),
            state: AccountSecurityState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        settingsRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `getBiometricAuthenticationType` returns the device's biometric
    /// authentication type. These tests use the iPhone 14 Pro, which should return `.faceID`.
    func test_perform_getBiometricAuthenticationType() async {
        await subject.perform(.getBiometricAuthenticationType)

        XCTAssertEqual(subject.state.biometricAuthenticationType, .faceID)
    }

    /// `receive(_:)` with `.logout` presents a logout confirmation alert.
    func test_receive_logout() async throws {
        subject.receive(.logout)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.logOut)
        XCTAssertEqual(alert.message, Localizations.logoutConfirmation)
        XCTAssertEqual(alert.preferredStyle, .alert)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.yes)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        // Tapping yes logs the user out.
        await alert.alertActions[0].handler?(alert.alertActions[0])

        XCTAssertTrue(settingsRepository.logoutCalled)
        XCTAssertEqual(coordinator.routes.last, .logout)
    }

    /// `receive(_:)` with `.toggleApproveLoginRequestsToggle` updates the state.
    func test_receive_toggleApproveLoginRequestsToggle() {
        subject.state.isApproveLoginRequestsToggleOn = false
        subject.receive(.toggleApproveLoginRequestsToggle(true))

        XCTAssertTrue(subject.state.isApproveLoginRequestsToggleOn)
    }

    /// `receive(_:)` with `.toggleUnlockWithFaceID` updates the state.
    func test_receive_toggleUnlockWithFaceID() {
        subject.state.isUnlockWithFaceIDOn = false
        subject.receive(.toggleUnlockWithFaceID(true))

        XCTAssertTrue(subject.state.isUnlockWithFaceIDOn)
    }

    /// `receive(_:)` with `.toggleUnlockWithPINCode` updates the state.
    func test_receive_toggleUnlockWithPINCode() {
        subject.state.isUnlockWithPINCodeOn = false
        subject.receive(.toggleUnlockWithPINCode(true))

        XCTAssertTrue(subject.state.isUnlockWithPINCodeOn)
    }

    /// `receive(_:)` with `.toggleUnlockWithTouchID` updates the state.
    func test_receive_toggleUnlockWithTouchID() {
        subject.state.isUnlockWithTouchIDToggleOn = false
        subject.receive(.toggleUnlockWithTouchID(true))

        XCTAssertTrue(subject.state.isUnlockWithTouchIDToggleOn)
    }
}
