import XCTest

@testable import BitwardenShared

class IntroCarouselProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var subject: IntroCarouselProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()

        subject = IntroCarouselProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: IntroCarouselState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.createAccount` navigates to the create account view.
    func test_receive_createAccount() {
        subject.receive(.createAccount)
        XCTAssertEqual(coordinator.routes.last, .createAccount)
    }

    /// `receive(_:)` with `.logIn` navigates to the landing view.
    func test_receive_logIn() {
        subject.receive(.logIn)
        XCTAssertEqual(coordinator.routes.last, .landing)
    }
}
