import XCTest

@testable import BitwardenShared

class MasterPasswordGuidanceProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<AuthRoute, AuthEvent>!
    var delegate: MockMasterPasswordUpdateDelegate!
    var subject: MasterPasswordGuidanceProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        delegate = MockMasterPasswordUpdateDelegate()
        subject = MasterPasswordGuidanceProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            delegate: delegate
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        delegate = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.dismiss` dismisses the view.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)
        XCTAssertEqual(coordinator.routes.last, .dismissPresented)
    }

    /// `receive(_:)` with `.generatePasswordPressed` navigates to the password generator view.
    @MainActor
    func test_receive_generatePasswordPressed() {
        subject.receive(.generatePasswordPressed)
        XCTAssertEqual(coordinator.routes.last, .masterPasswordGenerator)
        XCTAssertNotNil(coordinator.contexts.last as? MasterPasswordUpdateDelegate)
    }
}
