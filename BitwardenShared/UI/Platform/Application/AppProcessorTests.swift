import XCTest

@testable import BitwardenShared

class AppProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appModule: MockAppModule!
    var appSettingStore: MockAppSettingsStore!
    var subject: AppProcessor!
    var syncService: MockSyncService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appModule = MockAppModule()
        appSettingStore = MockAppSettingsStore()
        syncService = MockSyncService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = AppProcessor(
            appModule: appModule,
            services: ServiceContainer.withMocks(
                appSettingsStore: appSettingStore,
                syncService: syncService,
                vaultTimeoutService: vaultTimeoutService
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        appModule = nil
        subject = nil
        syncService = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `start(navigator:)` builds the AppCoordinator and navigates to vault unlock if there's an
    /// active account.
    func test_start_activeAccount() {
        appSettingStore.state = State.fixture()

        let rootNavigator = MockRootNavigator()

        subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        XCTAssertTrue(appModule.appCoordinator.isStarted)
        XCTAssertEqual(appModule.appCoordinator.routes, [.auth(.vaultUnlock(.fixture()))])
    }

    /// `start(navigator:)` builds the AppCoordinator and navigates to the landing view if there
    /// isn't an active account.
    func test_start_noActiveAccount() {
        let rootNavigator = MockRootNavigator()

        subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        XCTAssertTrue(appModule.appCoordinator.isStarted)
        XCTAssertEqual(appModule.appCoordinator.routes, [.auth(.landing)])
    }
}
