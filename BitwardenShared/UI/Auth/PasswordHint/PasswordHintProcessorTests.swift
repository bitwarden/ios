import XCTest

@testable import BitwardenShared

// MARK: - PasswordHintProcessorTests

class PasswordHintProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AuthRoute>!
    var subject: PasswordHintProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        let state = PasswordHintState()
        subject = PasswordHintProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(),
            state: state
        )
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `perform()` with `.submitPressed` submits the request for the master password hint.
    func test_perform_submitPressed() async {
        await subject.perform(.submitPressed)
        XCTFail("This test has not been implemented yet.")
    }

    /// `receive()` with `.dismissPressed` navigates to the `.dismiss` route.
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive()` with `.emailAddressChanged` and an empty value updates the state to reflect the
    /// changes.
    func test_receive_emailAddressChanged_withoutValue() {
        subject.state.emailAddress = "email@example.com"
        subject.receive(.emailAddressChanged(""))

        XCTAssertEqual(subject.state.emailAddress, "")
        XCTAssertFalse(subject.state.isSubmitButtonEnabled)
    }

    /// `receive()` with `.emailAddressChanged` and a value updates the state to reflect the
    /// changes.
    func test_receive_emailAddressChanged_withValue() {
        subject.state.emailAddress = ""
        subject.receive(.emailAddressChanged("email@example.com"))

        XCTAssertEqual(subject.state.emailAddress, "email@example.com")
        XCTAssertTrue(subject.state.isSubmitButtonEnabled)
    }
}
