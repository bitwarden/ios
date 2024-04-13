import XCTest

@testable import AuthenticatorShared

class SettingsProcessorTests: AuthenticatorTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var subject: SettingsProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        subject = SettingsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: SettingsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// Receiving `.aboutPressed` navigates to the about screen.
    func test_receive_aboutPressed() {
        subject.receive(.aboutPressed)

        XCTAssertEqual(coordinator.routes.last, .about)
    }

    /// Receiving `.appearancePressed` navigates to the appearance screen.
    func test_receive_appearancePressed() {
        subject.receive(.appearancePressed)

        XCTAssertEqual(coordinator.routes.last, .appearance)
    }
}
