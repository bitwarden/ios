import XCTest

@testable import BitwardenShared

class AttachmentsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultItemRoute>!
    var errorReporter: MockErrorReporter!
    var subject: AttachmentsProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()

        subject = AttachmentsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter
            ),
            state: AttachmentsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.chooseFilePressed` shows the attachment options alert.
    func test_receive_chooseFilePressed() {
        subject.receive(.chooseFilePressed)

        XCTAssertEqual(coordinator.alertShown.last, .fileSelectionOptions(handler: { _ in }))
    }

    /// `receive(_:)` with `.dismissPressed` dismisses the view.
    func test_receive_dismissPressed() {
        subject.receive(.dismissPressed)

        XCTAssertEqual(coordinator.routes.last, .dismiss())
    }
}
