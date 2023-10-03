import XCTest

@testable import BitwardenShared

// MARK: - LandingProcessorTests

class LandingProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AuthRoute>!
    var subject: LandingProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator<AuthRoute>()

        let state = LandingState()
        subject = LandingProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: state
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.continuePressed` navigates to the login screen.
    func test_receive_continuePressed() {
        subject.state.email = "email@example.com"

        subject.receive(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .login(
            username: "email@example.com",
            region: "region",
            isLoginWithDeviceVisible: false
        ))
    }

    /// `receive(_:)` with `.createAccountPressed` navigates to the create account screen.
    func test_receive_createAccountPressed() {
        subject.receive(.createAccountPressed)
        XCTAssertEqual(coordinator.routes.last, .createAccount)
    }

    /// `receive(_:)` with `.emailChanged` and an empty value updates the state to reflect the changes.
    func test_receive_emailChanged_empty() {
        subject.state.email = "email@example.com"

        subject.receive(.emailChanged(""))
        XCTAssertEqual(subject.state.email, "")
        XCTAssertFalse(subject.state.isContinueButtonEnabled)
    }

    /// `receive(_:)` with `.emailChanged` and an email value updates the state to reflect the changes.
    func test_receive_emailChanged_value() {
        XCTAssertEqual(subject.state.email, "")

        subject.receive(.emailChanged("email@example.com"))
        XCTAssertEqual(subject.state.email, "email@example.com")
        XCTAssertTrue(subject.state.isContinueButtonEnabled)
    }

    /// `receive(_:)` with `.regionPressed` navigates to the region selection screen.
    func test_receive_regionPressed() {
        subject.receive(.regionPressed)
        XCTAssertEqual(coordinator.routes.last, .regionSelection)
    }

    /// `receive(_:)` with `.emailChanged` updates the state to reflect the changes.
    func test_receive_rememberMeChanged() {
        XCTAssertFalse(subject.state.isRememberMeOn)

        subject.receive(.rememberMeChanged(true))
        XCTAssertTrue(subject.state.isRememberMeOn)
    }
}
