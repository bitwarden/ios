import XCTest

@testable import BitwardenShared

class AppProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appModule: MockAppModule!
    var appSettingStore: MockAppSettingsStore!
    var subject: AppProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appModule = MockAppModule()
        appSettingStore = MockAppSettingsStore()
        subject = AppProcessor(
            appModule: appModule,
            services: ServiceContainer.withMocks(
                appSettingsStore: appSettingStore
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        appModule = nil
        subject = nil
    }

    // MARK: Tests

    /// `start(navigator:)` builds the AppCoordinator and navigates to vault unlock if there's an
    /// active account.
    func test_start_activeAccount() {
        appSettingStore.state = State.fixture()

        let rootNavigator = MockRootNavigator()

        subject.start(navigator: rootNavigator)

        XCTAssertTrue(appModule.appCoordinator.isStarted)
        XCTAssertEqual(appModule.appCoordinator.routes, [.auth(.vaultUnlock)])
    }

    /// `start(navigator:)` builds the AppCoordinator and navigates to the landing view if there
    /// isn't an active account.
    func test_start_noActiveAccount() {
        let rootNavigator = MockRootNavigator()

        subject.start(navigator: rootNavigator)

        XCTAssertTrue(appModule.appCoordinator.isStarted)
        XCTAssertEqual(appModule.appCoordinator.routes, [.auth(.landing)])
    }
}
