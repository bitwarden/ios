import XCTest

@testable import BitwardenShared

class DeleteAccountProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var subject: DeleteAccountProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        subject = DeleteAccountProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: DeleteAccountState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// Receiving `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }
}
