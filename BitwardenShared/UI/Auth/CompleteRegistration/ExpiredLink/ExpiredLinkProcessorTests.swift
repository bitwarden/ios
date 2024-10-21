import AuthenticationServices
import Networking
import XCTest

@testable import BitwardenShared

// MARK: - ExpiredLinkProcessorTests

class ExpiredLinkProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var subject: ExpiredLinkProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator<AuthRoute, AuthEvent>()
        subject = ExpiredLinkProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: ExpiredLinkState()
        )
    }

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.dismissTapped` dismisses the view.
    @MainActor
    func test_receive_dismissTapped() {
        subject.receive(.dismissTapped)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.logInTapped` dismisses the view.
    @MainActor
    func test_receive_logInTapped() {
        subject.receive(.logInTapped)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.restartRegistrationTapped` dismisses the all views and launches start registration view.
    @MainActor
    func restartRegistrationTapped() {
        subject.receive(.restartRegistrationTapped)
        XCTAssertEqual(coordinator.routes.last, .startRegistrationFromExpiredLink)
    }
}
