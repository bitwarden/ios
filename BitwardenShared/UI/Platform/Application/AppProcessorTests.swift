import Foundation
import XCTest

@testable import BitwardenShared

class AppProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appModule: MockAppModule!
    var appSettingStore: MockAppSettingsStore!
    var dateProvider: MockDateProvider!
    var notificationCenterService: MockNotificationCenterService!
    var stateService: MockStateService!
    var subject: AppProcessor!
    var syncService: MockSyncService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appModule = MockAppModule()
        appSettingStore = MockAppSettingsStore()
        dateProvider = MockDateProvider()
        notificationCenterService = MockNotificationCenterService()
        stateService = MockStateService()
        syncService = MockSyncService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = AppProcessor(
            appModule: appModule,
            services: ServiceContainer.withMocks(
                appSettingsStore: appSettingStore,
                stateService: stateService,
                syncService: syncService,
                vaultTimeoutService: vaultTimeoutService
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        appModule = nil
        appSettingStore = nil
        dateProvider = nil
        notificationCenterService = nil
        stateService = nil
        subject = nil
        syncService = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// The user's last active time is updated when the app is backgrounded.
    func test_appBackgrounded_setLastActiveTime() {
        let account: Account = .fixture()
        stateService.activeAccount = account

        vaultTimeoutService.lastActiveTime[account.profile.userId] = .distantPast

        notificationCenterService.didEnterBackgroundSubject.send()
        waitFor(vaultTimeoutService.lastActiveTime[account.profile.userId] != .distantPast)

        let updated = vaultTimeoutService.lastActiveTime[account.profile.userId]

        XCTAssertEqual(dateProvider.now, updated)
    }

    /// Upon a session timeout on app foreground, the user should be navigated to the landing screen.
    func test_shouldSessionTimeout_navigateTo_landing() async throws {
        let rootNavigator = MockRootNavigator()
        let account: Account = .fixture()

        appSettingStore.timeoutAction[account.profile.userId] = .logout
        appSettingStore.state = State(
            accounts: [account.profile.userId: account],
            activeUserId: account.profile.userId
        )
        stateService.activeAccount = account
        stateService.accounts = [account]
        appSettingStore.vaultTimeout[account.profile.userId] = -1
        vaultTimeoutService.shouldSessionTimeout[account.profile.userId] = true

        subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        notificationCenterService.willEnterForegroundSubject.send()
        waitFor(vaultTimeoutService.shouldSessionTimeout[account.profile.userId] == true)

        XCTAssertEqual(appModule.appCoordinator.routes.last, .auth(.landing))
    }

    /// Upon a session timeout on app foreground, the user should be navigated to the vault unlock screen.
    func test_shouldSessionTimeout_navigateTo_vaultUnlock() async throws {
        let rootNavigator = MockRootNavigator()
        let account: Account = .fixture()

        appSettingStore.timeoutAction[account.profile.userId] = .lock
        appSettingStore.state = State(
            accounts: [account.profile.userId: account],
            activeUserId: account.profile.userId
        )
        stateService.activeAccount = account
        stateService.accounts = [account]

        vaultTimeoutService.shouldSessionTimeout[account.profile.userId] = true
        subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        notificationCenterService.willEnterForegroundSubject.send()
        waitFor(vaultTimeoutService.shouldSessionTimeout[account.profile.userId] == true)

        XCTAssertEqual(appModule.appCoordinator.routes.last, .auth(.vaultUnlock(account)))
    }

    /// `start(navigator:)` builds the AppCoordinator and navigates to vault unlock if there's an
    /// active account.
    func test_start_activeAccount() async throws {
        appSettingStore.state = State.fixture()
        appSettingStore.vaultTimeout = [Account.fixture().profile.userId: 60]
        let rootNavigator = MockRootNavigator()

        subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        XCTAssertTrue(appModule.appCoordinator.isStarted)
        XCTAssertEqual(appModule.appCoordinator.routes.last, .auth(.vaultUnlock(.fixture())))
    }

    /// `start(navigator:)` builds the AppCoordinator and navigates to the landing view if there
    /// isn't an active account.
    func test_start_noActiveAccount() {
        let rootNavigator = MockRootNavigator()

        subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        XCTAssertTrue(appModule.appCoordinator.isStarted)
        XCTAssertEqual(appModule.appCoordinator.routes, [.auth(.landing)])
    }

    /// `start(navigator:)` subscribes to the vault timeout service publisher and clears any cached
    ///  data if it receives the value to clear cached data.
    func test_start_shouldClearData() {
        let rootNavigator = MockRootNavigator()

        subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        vaultTimeoutService.shouldClearSubject.send(true)

        waitFor { syncService.didClearCachedData }
        XCTAssertTrue(syncService.didClearCachedData)
    }

    /// `start(navigator:)` subscribes to the vault timeout service publisher and does not clear
    /// any cached data if the published value is false.
    func test_start_shouldNotClearData() {
        let rootNavigator = MockRootNavigator()

        subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        vaultTimeoutService.shouldClearSubject.send(false)

        XCTAssertFalse(syncService.didClearCachedData)
    }
}
