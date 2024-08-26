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
    @MainActor
    func test_receive_createAccount() {
        subject.receive(.createAccount)
        XCTAssertEqual(coordinator.routes.last, .createAccount)
    }

    /// `receive(_:)` with `.currentPageIndexChanged` updates the current page index.
    @MainActor
    func test_receive_currentPageIndexChanged() {
        subject.receive(.currentPageIndexChanged(1))
        XCTAssertEqual(subject.state.currentPageIndex, 1)

        subject.receive(.currentPageIndexChanged(2))
        XCTAssertEqual(subject.state.currentPageIndex, 2)

        subject.receive(.currentPageIndexChanged(0))
        XCTAssertEqual(subject.state.currentPageIndex, 0)
    }

    /// `receive(_:)` with `.logIn` navigates to the landing view.
    @MainActor
    func test_receive_logIn() {
        subject.receive(.logIn)
        XCTAssertEqual(coordinator.routes.last, .landing)
    }
}
