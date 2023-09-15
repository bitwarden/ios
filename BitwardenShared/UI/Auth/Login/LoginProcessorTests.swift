import XCTest

@testable import BitwardenShared

// MARK: - LoginProcessorTests

class LoginProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AuthRoute>!
    var subject: LoginProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        subject = LoginProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: LoginState()
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.enterpriseSingleSignOnPressed` navigates to the enterprise single sign-on screen.
    func test_receive_enterpriseSingleSignOnPressed() {
        subject.receive(.enterpriseSingleSignOnPressed)
        XCTAssertEqual(coordinator.routes.last, .enterpriseSingleSignOn)
    }

    /// `receive(_:)` with `.getMasterPasswordHintPressed` navigates to the master password hint screen.
    func test_receive_getMasterPasswordHintPressed() {
        subject.receive(.getMasterPasswordHintPressed)
        XCTAssertEqual(coordinator.routes.last, .masterPasswordHint)
    }

    /// `receive(_:)` with `.loginWithDevicePressed` navigates to the login with device screen.
    func test_receive_loginWithDevicePressed() {
        subject.receive(.loginWithDevicePressed)
        XCTAssertEqual(coordinator.routes.last, .loginWithDevice)
    }

    /// `receive(_:)` with `.loginWithMasterPasswordPressed` logs the user in with the provided master password.
    func test_receive_loginWithMasterPasswordPressed() {
        subject.receive(.loginWithMasterPasswordPressed)

        // Temporary assertion until login functionality is added: BIT-132
        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `receive(_:)` with `.masterPasswordChanged` updates the state to reflect the changes.
    func test_receive_masterPasswordChanged() {
        subject.state.masterPassword = ""

        subject.receive(.masterPasswordChanged("password"))
        XCTAssertEqual(subject.state.masterPassword, "password")
    }

    /// `receive(_:)` with `.morePressed` navigates to the login options screen.
    func test_receive_morePressed() {
        subject.receive(.morePressed)
        XCTAssertEqual(coordinator.routes.last, .loginOptions)
    }

    /// `receive(_:)` with `.notYouPressed` navigates to the landing screen.
    func test_receive_notYouPressed() {
        subject.receive(.notYouPressed)
        XCTAssertEqual(coordinator.routes.last, .landing)
    }

    /// `receive(_:)` with `.revealMasterPasswordFieldPressed` updates the state to reflect the changes.
    func test_receive_revealMasterPasswordFieldPressed() {
        subject.state.isMasterPasswordRevealed = false
        subject.receive(.revealMasterPasswordFieldPressed)
        XCTAssertTrue(subject.state.isMasterPasswordRevealed)

        subject.receive(.revealMasterPasswordFieldPressed)
        XCTAssertFalse(subject.state.isMasterPasswordRevealed)
    }
}
