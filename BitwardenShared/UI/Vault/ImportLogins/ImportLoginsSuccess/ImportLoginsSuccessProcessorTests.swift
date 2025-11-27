import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

class ImportLoginsSuccessProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<ImportLoginsRoute, ImportLoginsEvent>!
    var subject: ImportLoginsSuccessProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator()

        subject = ImportLoginsSuccessProcessor(
            coordinator: coordinator.asAnyCoordinator(),
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.dismiss` notifies the coordinator that import logins has completed.
    @MainActor
    func test_perform_dismiss() async {
        await subject.perform(.dismiss)
        XCTAssertEqual(coordinator.events.last, .completeImportLogins)
    }
}
