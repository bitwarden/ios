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

    /// `receive(_:)` with `.continuePressed` and an invalid email navigates to the `.alert` route.
    func test_receive_continuePressed_withInvalidEmail() {
        subject.state.email = "email"

        subject.receive(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .alert(Alert(
            title: Localizations.anErrorHasOccurred,
            message: Localizations.invalidEmail,
            alertActions: [
                AlertAction(title: Localizations.ok, style: .default),
            ]
        )))
    }

    /// `receive(_:)` with `.continuePressed` and a valid email navigates to the login screen.
    func test_receive_continuePressed_withValidEmail() {
        subject.state.email = "email@example.com"

        subject.receive(.continuePressed)
        XCTAssertEqual(coordinator.routes.last, .login(
            username: "email@example.com",
            region: .unitedStates,
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
    func test_receive_regionPressed() throws {
        subject.receive(.regionPressed)

        let route = coordinator.routes.last
        guard let route, case let AuthRoute.alert(alert) = route
        else {
            XCTFail("The last route was not an `.alert`: \(String(describing: route))")
            return
        }
        XCTAssertEqual(alert.title, Localizations.loggingInOn)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions.count, 4)

        XCTAssertEqual(alert.alertActions[0].title, "bitwarden.com")
        alert.alertActions[0].handler?(alert.alertActions[0])
        XCTAssertEqual(subject.state.region, .unitedStates)

        XCTAssertEqual(alert.alertActions[1].title, "bitwarden.eu")
        alert.alertActions[1].handler?(alert.alertActions[1])
        XCTAssertEqual(subject.state.region, .europe)

        XCTAssertEqual(alert.alertActions[2].title, Localizations.selfHosted)
        alert.alertActions[2].handler?(alert.alertActions[2])
        XCTAssertEqual(subject.state.region, .selfHosted)
    }

    /// `receive(_:)` with `.emailChanged` updates the state to reflect the changes.
    func test_receive_rememberMeChanged() {
        XCTAssertFalse(subject.state.isRememberMeOn)

        subject.receive(.rememberMeChanged(true))
        XCTAssertTrue(subject.state.isRememberMeOn)
    }
}
