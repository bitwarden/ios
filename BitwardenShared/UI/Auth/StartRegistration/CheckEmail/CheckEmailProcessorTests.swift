import Networking
import XCTest

@testable import BitwardenShared

// MARK: - CheckEmailProcessorTests

class CheckEmailProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var subject: CheckEmailProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        subject = CheckEmailProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: CheckEmailState()
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismissTapped() {
        subject.receive(.dismissTapped)
        XCTAssertEqual(coordinator.routes.last, .dismissPresented)
    }

    /// `receive(_:)` with `.goBackTapped` dismisses the view.
    @MainActor
    func test_receive_goBackTapped() {
        subject.receive(.goBackTapped)
        XCTAssertEqual(coordinator.routes.last, .dismissPresented)
    }

    /// `receive(_:)` with `.logInTapped` dismisses the view.
    @MainActor
    func test_receive_logInTapped() {
        subject.receive(.logInTapped)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }
}
