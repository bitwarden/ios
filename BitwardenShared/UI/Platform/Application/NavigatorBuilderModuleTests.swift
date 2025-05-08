import XCTest

@testable import BitwardenShared

class NavigatorBuilderModuleTests: BitwardenTestCase {
    // MARK: Properties

    var subject: DefaultAppModule!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DefaultAppModule(services: .withMocks())
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `makeNavigationController()` builds a navigation controller.
    @MainActor
    func test_makeNavigationController() {
        let navigationController = subject.makeNavigationController()
        XCTAssertTrue(navigationController is ViewLoggingNavigationController)
    }
}
