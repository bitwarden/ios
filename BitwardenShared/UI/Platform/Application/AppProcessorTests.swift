import XCTest

@testable import BitwardenShared

class AppProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appModule: MockAppModule!
    var subject: AppProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appModule = MockAppModule()
        subject = AppProcessor(appModule: appModule, services: ServiceContainer.withMocks())
    }

    override func tearDown() {
        super.tearDown()

        appModule = nil
        subject = nil
    }

    // MARK: Tests

    /// `start(navigator:)` builds the AppCoordinator and navigates to the initial route.
    func test_start() {
        let rootNavigator = MockRootNavigator()

        subject.start(navigator: rootNavigator)

        XCTAssertTrue(appModule.appCoordinator.isStarted)
        XCTAssertEqual(appModule.appCoordinator.routes, [.auth(.landing)])
    }
}
