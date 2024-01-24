import Foundation
import XCTest

@testable import BitwardenShared

class AppProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appModule: MockAppModule!
    var appSettingStore: MockAppSettingsStore!
    var errorReporter: MockErrorReporter!
    var notificationCenterService: MockNotificationCenterService!
    var notificationService: MockNotificationService!
    var stateService: MockStateService!
    var subject: AppProcessor!
    var syncService: MockSyncService!
    var timeProvider: MockTimeProvider!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appModule = MockAppModule()
        appSettingStore = MockAppSettingsStore()
        errorReporter = MockErrorReporter()
        notificationCenterService = MockNotificationCenterService()
        notificationService = MockNotificationService()
        stateService = MockStateService()
        syncService = MockSyncService()
        timeProvider = MockTimeProvider(.currentTime)
        vaultTimeoutService = MockVaultTimeoutService()

        subject = AppProcessor(
            appModule: appModule,
            services: ServiceContainer.withMocks(
                appSettingsStore: appSettingStore,
                errorReporter: errorReporter,
                notificationService: notificationService,
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
        errorReporter = nil
        notificationCenterService = nil
        notificationService = nil
        stateService = nil
        subject = nil
        syncService = nil
        timeProvider = nil
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

        XCTAssertEqual(timeProvider.presentTime.timeIntervalSince1970, updated!.timeIntervalSince1970, accuracy: 1.0)
    }

    /// `didRegister(withToken:)` passes the token to the notification service.
    func test_didRegister() throws {
        let tokenData = try XCTUnwrap("tokensForFree".data(using: .utf8))

        let task = Task {
            subject.didRegister(withToken: tokenData)
        }

        waitFor(notificationService.registrationTokenData == tokenData)
        task.cancel()
    }

    /// `failedToRegister(_:)` records the error.
    func test_failedToRegister() {
        subject.failedToRegister(BitwardenTestError.example)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `messageReceived(_:notificationDismissed:notificationTapped)` passes the data to the notification service.
    func test_messageReceived() async {
        let message: [AnyHashable: Any] = ["knock knock": "who's there?"]

        await subject.messageReceived(message)

        XCTAssertEqual(notificationService.messageReceivedMessage?.keys.first, "knock knock")
    }

    /// Upon a session timeout on app foreground, the user should be navigated to the landing screen.
    func test_shouldSessionTimeout_navigateTo_landing() async throws {
        let rootNavigator = MockRootNavigator()
        let account: Account = .fixture()

        appSettingStore.timeoutAction[account.profile.userId] = SessionTimeoutAction.logout.rawValue
        appSettingStore.state = State(
            accounts: [account.profile.userId: account],
            activeUserId: account.profile.userId
        )
        stateService.activeAccount = account
        stateService.accounts = [account]
        appSettingStore.vaultTimeout[account.profile.userId] = SessionTimeoutValue.onAppRestart.rawValue
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

        appSettingStore.timeoutAction[account.profile.userId] = SessionTimeoutAction.lock.rawValue
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

        XCTAssertEqual(
            appModule.appCoordinator.routes.last,
            .auth(.vaultUnlock(
                .fixture(),
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false
            ))
        )
    }

    /// `start(navigator:)` builds the AppCoordinator and navigates to vault unlock if there's an
    /// active account.
    func test_start_activeAccount() async throws {
        appSettingStore.state = State.fixture()
        appSettingStore.vaultTimeout = [Account.fixture().profile.userId: 60]
        let rootNavigator = MockRootNavigator()

        subject.start(appContext: .mainApp, navigator: rootNavigator, window: nil)

        XCTAssertTrue(appModule.appCoordinator.isStarted)
        XCTAssertEqual(
            appModule.appCoordinator.routes.last,
            .auth(.vaultUnlock(
                .fixture(),
                attemptAutomaticBiometricUnlock: true,
                didSwitchAccountAutomatically: false
            ))
        )
    }

    /// `start(navigator:)` builds the AppCoordinator and navigates to the initial route if provided.
    func test_start_initialRoute() {
        let rootNavigator = MockRootNavigator()

        subject.start(
            appContext: .mainApp,
            initialRoute: .extensionSetup(.extensionActivation(type: .appExtension)),
            navigator: rootNavigator,
            window: nil
        )

        XCTAssertTrue(appModule.appCoordinator.isStarted)
        XCTAssertEqual(
            appModule.appCoordinator.routes,
            [.extensionSetup(.extensionActivation(type: .appExtension))]
        )
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
