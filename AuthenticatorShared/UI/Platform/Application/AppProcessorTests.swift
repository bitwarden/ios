import BitwardenKit
import BitwardenKitMocks
import Foundation
import XCTest

@testable import AuthenticatorShared

class AppProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var appModule: MockAppModule!
    var appSettingsStore: MockAppSettingsStore!
    var coordinator: MockCoordinator<AppRoute, AppEvent>!
    var errorReporter: MockErrorReporter!
    var notificationCenter: MockNotificationCenterService!
    var subject: AppProcessor!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appModule = MockAppModule()
        appSettingsStore = MockAppSettingsStore()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        notificationCenter = MockNotificationCenterService()
        timeProvider = MockTimeProvider(.mockTime(Date(year: 2024, month: 6, day: 1, hour: 2, minute: 30, second: 10)))

        subject = AppProcessor(
            appModule: appModule,
            services: ServiceContainer.withMocks(
                appSettingsStore: appSettingsStore,
                errorReporter: errorReporter,
                notificationCenterService: notificationCenter,
                timeProvider: timeProvider,
            ),
        )
        subject.coordinator = coordinator.asAnyCoordinator()
    }

    override func tearDown() {
        super.tearDown()

        appModule = nil
        appSettingsStore = nil
        coordinator = nil
        errorReporter = nil
        notificationCenter = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    @MainActor
    func test_background_storesLastActive() async throws {
        await subject.start(appContext: .mainApp,
                            navigator: MockRootNavigator(),
                            window: window)

        try await ensureNotificationsSubscriptionsListening()

        notificationCenter.didEnterBackgroundSubject.send()
        let userId = appSettingsStore.localUserId

        try await waitForAsync {
            self.appSettingsStore.lastActiveTime[userId] != nil
        }

        XCTAssertNotNil(appSettingsStore.lastActiveTime[userId])
    }

    /// `showDebugMenu` will send the correct route to the coordinator.
    @MainActor
    func test_showDebugMenu() {
        subject.showDebugMenu()
        XCTAssertEqual(coordinator.routes.last, .debugMenu)
    }

    /// When the timeout is set to `.never`, the `AppProcessor` **never** sends the `.vaultTimeout` event.
    @MainActor
    func test_vaultTimeout_never() async throws {
        let userId = await subject.services.stateService.getActiveAccountId()
        appSettingsStore.setLastActiveTime(timeProvider.presentTime.advanced(by: -3601), userId: userId)
        appSettingsStore.setVaultTimeout(minutes: SessionTimeoutValue.never.rawValue, userId: userId)

        var notificationReceived = false
        let publisher = notificationCenter.willEnterForegroundPublisher()
            .sink { _ in
                notificationReceived = true
            }
        defer { publisher.cancel() }

        try await ensureNotificationsSubscriptionsListening()

        notificationCenter.willEnterForegroundSubject.send()

        try await waitForAsync { notificationReceived }
        XCTAssertTrue(coordinator.events.isEmpty)
    }

    /// When the timeout is not set (i.e. `nil`), the `AppProcessor` **does not** send the `.vaultTimeout` event.
    @MainActor
    func test_vaultTimeout_notSet() async throws {
        let userId = await subject.services.stateService.getActiveAccountId()
        appSettingsStore.setLastActiveTime(timeProvider.presentTime.advanced(by: -3601), userId: userId)

        var notificationReceived = false
        let publisher = notificationCenter.willEnterForegroundPublisher()
            .sink { _ in
                notificationReceived = true
            }
        defer { publisher.cancel() }

        try await ensureNotificationsSubscriptionsListening()

        notificationCenter.willEnterForegroundSubject.send()

        try await waitForAsync { notificationReceived }
        XCTAssertTrue(coordinator.events.isEmpty)
    }

    /// When the timeout is set to `.onAppRestart`, the `AppProcessor` does not send the `.vaultTimeout` event.
    /// It will be handled instead when the Coordinator starts up.
    @MainActor
    func test_vaultTimeout_onAppRestart() async throws {
        let userId = await subject.services.stateService.getActiveAccountId()
        appSettingsStore.setLastActiveTime(timeProvider.presentTime.advanced(by: -3601), userId: userId)
        appSettingsStore.setVaultTimeout(minutes: SessionTimeoutValue.onAppRestart.rawValue, userId: userId)

        var notificationReceived = false
        let publisher = notificationCenter.willEnterForegroundPublisher()
            .sink { _ in
                notificationReceived = true
            }
        defer { publisher.cancel() }

        try await ensureNotificationsSubscriptionsListening()

        notificationCenter.willEnterForegroundSubject.send()

        try await waitForAsync { notificationReceived }
        XCTAssertTrue(coordinator.events.isEmpty)
    }

    /// When the user has no previous `lastActiveTime` stored, the timeout always occurs.
    @MainActor
    func test_vaultTimeout_oneMinute_noLastActive() async throws {
        let userId = await subject.services.stateService.getActiveAccountId()
        appSettingsStore.lastActiveTime.removeValue(forKey: userId)
        appSettingsStore.setVaultTimeout(minutes: 1, userId: userId)

        var notificationReceived = false
        let publisher = notificationCenter.willEnterForegroundPublisher()
            .sink { _ in
                notificationReceived = true
            }
        defer { publisher.cancel() }

        try await ensureNotificationsSubscriptionsListening()

        notificationCenter.willEnterForegroundSubject.send()

        try await waitForAsync { notificationReceived }
        try await waitForAsync { !self.coordinator.events.isEmpty }
        XCTAssertEqual(coordinator.events.last, .vaultTimeout)
    }

    /// When the timeout has not yet passed, the `AppProcessor` does **not** send the `.vaultTimeout` event.
    @MainActor
    func test_vaultTimeout_oneMinute_notYetTimedOut() async throws {
        let userId = await subject.services.stateService.getActiveAccountId()
        appSettingsStore.setLastActiveTime(timeProvider.presentTime, userId: userId)
        appSettingsStore.setVaultTimeout(minutes: 1, userId: userId)

        var notificationReceived = false
        let publisher = notificationCenter.willEnterForegroundPublisher()
            .sink { _ in
                notificationReceived = true
            }
        defer { publisher.cancel() }

        try await ensureNotificationsSubscriptionsListening()

        notificationCenter.willEnterForegroundSubject.send()

        try await waitForAsync { notificationReceived }
        XCTAssertTrue(coordinator.events.isEmpty)
    }

    /// When the one minute timeout length has passed, the `AppProcessor` sends  the `.vaultTimeout` event.
    @MainActor
    func test_vaultTimeout_oneMinute_timeout() async throws {
        let userId = await subject.services.stateService.getActiveAccountId()
        appSettingsStore.setLastActiveTime(timeProvider.presentTime.advanced(by: -120), userId: userId)
        appSettingsStore.setVaultTimeout(minutes: 1, userId: userId)

        var notificationReceived = false
        let publisher = notificationCenter.willEnterForegroundPublisher()
            .sink { _ in
                notificationReceived = true
            }
        defer { publisher.cancel() }

        try await ensureNotificationsSubscriptionsListening()

        notificationCenter.willEnterForegroundSubject.send()

        try await waitForAsync { notificationReceived }
        try await waitForAsync { !self.coordinator.events.isEmpty }
        XCTAssertEqual(coordinator.events.last, .vaultTimeout)
    }

    /// When the one hour timeout length has passed, the `AppProcessor` sends  the `.vaultTimeout` event.
    @MainActor
    func test_vaultTimeout_oneHour_timeout() async throws {
        let userId = await subject.services.stateService.getActiveAccountId()
        appSettingsStore.setLastActiveTime(timeProvider.presentTime.advanced(by: -3700), userId: userId)
        appSettingsStore.setVaultTimeout(minutes: 60, userId: userId)

        notificationCenter.willEnterForegroundSubject.send()

        var notificationReceived = false
        let publisher = notificationCenter.willEnterForegroundPublisher()
            .sink { _ in
                notificationReceived = true
            }
        defer { publisher.cancel() }

        try await ensureNotificationsSubscriptionsListening()

        notificationCenter.willEnterForegroundSubject.send()

        try await waitForAsync { notificationReceived }
        try await waitForAsync { !self.coordinator.events.isEmpty }
        XCTAssertEqual(coordinator.events.last, .vaultTimeout)
    }

    // MARK: Private

    /// Ensures that the subscriptions to notifications are listening to avoid race-conditions. This is done
    /// by checking the Tasks that starts the subscription have started.
    @MainActor
    private func ensureNotificationsSubscriptionsListening() async throws {
        try await waitForAsync { self.subject.notificationsListeningCount == 2 }
    }
}
