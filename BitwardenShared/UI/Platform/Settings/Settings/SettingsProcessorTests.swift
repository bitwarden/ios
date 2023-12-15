import XCTest

@testable import BitwardenShared

class SettingsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
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

    /// Receiving `.autoFillPressed` navigates to the auto-fill screen.
    func test_receive_autoFillPressed() {
        subject.receive(.autoFillPressed)

        XCTAssertEqual(coordinator.routes.last, .autoFill)
    }

    /// Receiving `.accountSecurityPressed` navigates to the account security screen.
    func test_receive_accountSecurityPressed() {
        subject.receive(.accountSecurityPressed)

        XCTAssertEqual(coordinator.routes.last, .accountSecurity)
    }

    /// Receiving `.otherPressed` navigates to the other screen.
    func test_receive_otherPressed() {
        subject.receive(.otherPressed)

        XCTAssertEqual(coordinator.routes.last, .other)
    }

    /// Receiving `.vaultPressed` navigates to the vault settings screen.
    func test_receive_vaultPressed() {
        subject.receive(.vaultPressed)

        XCTAssertEqual(coordinator.routes.last, .vault)
    }
}
