import XCTest

@testable import BitwardenShared

class RemoveMasterPasswordProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var subject: RemoveMasterPasswordProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()

        subject = RemoveMasterPasswordProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: RemoveMasterPasswordState(
                organizationName: "Example Org"
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.continueFlow` removes the user's master password and completes auth.
    @MainActor
    func test_receive_continueFlow() {
        subject.receive(.continueFlow)
        // TODO: PM-11152 Migrate user and complete auth
    }
}
