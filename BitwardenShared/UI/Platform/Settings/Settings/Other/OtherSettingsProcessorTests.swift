import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared

class OtherSettingsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var configService: MockConfigService!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var errorReporter: MockErrorReporter!
    var settingsRepository: MockSettingsRepository!
    var subject: OtherSettingsProcessor!
    var watchService: MockWatchService!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
        errorReporter = MockErrorReporter()
        settingsRepository = MockSettingsRepository()
        watchService = MockWatchService()
        subject = OtherSettingsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                configService: configService,
                errorReporter: errorReporter,
                settingsRepository: settingsRepository,
                watchService: watchService
            ),
            state: OtherSettingsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        configService = nil
        coordinator = nil
        errorReporter = nil
        settingsRepository = nil
        subject = nil
        watchService = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.loadInitialValues` records an error if getting the allow sync
    /// on refresh value fails.
    func test_perform_loadInitialValues_error() async {
        settingsRepository.allowSyncOnRefreshResult = .failure(BitwardenTestError.example)

        await subject.perform(.loadInitialValues)

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `perform(_:)` with `.loadInitialValues` fetches the allow sync on refresh value.
    @MainActor
    func test_perform_loadInitialValues_success() async {
        settingsRepository.allowSyncOnRefresh = true
        settingsRepository.clearClipboardValue = .thirtySeconds
        settingsRepository.connectToWatch = true
        settingsRepository.getSiriAndShortcutsAccessResult = .success(true)
        watchService.isSupportedValue = true

        await subject.perform(.loadInitialValues)

        XCTAssertEqual(subject.state.clearClipboardValue, .thirtySeconds)
        XCTAssertTrue(subject.state.isAllowSyncOnRefreshToggleOn)
        XCTAssertTrue(subject.state.isConnectToWatchToggleOn)
        XCTAssertTrue(subject.state.isSiriAndShortcutsAccessToggleOn)
        XCTAssertTrue(subject.state.shouldShowConnectToWatchToggle)
    }

    /// `perform(_:)` with `.streamLastSyncTime` updates the state's last sync time whenever it changes.
    @MainActor
    func test_perform_streamLastSyncTime() {
        let task = Task {
            await subject.perform(.streamLastSyncTime)
        }

        let date = Date(year: 2023, month: 12, day: 1)
        settingsRepository.lastSyncTimeSubject.value = date

        waitFor { subject.state.lastSyncDate != nil }
        task.cancel()

        XCTAssertEqual(subject.state.lastSyncDate, date)
    }

    /// `perform(_:)` with `.streamLastSyncTime` logs an error if getting the last sync time fails.
    func test_perform_streamLastSyncTime_error() async {
        settingsRepository.lastSyncTimeError = StateServiceError.noActiveAccount

        await subject.perform(.streamLastSyncTime)

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `perform(_:)` with `.syncNow` shows the loading overlay while syncing and then a toast if
    /// it completes successfully.
    @MainActor
    func test_perform_syncNow() async {
        await subject.perform(.syncNow)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.syncing)])
        XCTAssertTrue(settingsRepository.fetchSyncCalled)
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.syncingComplete))
    }

    /// `perform(_:)` with `.syncNow` shows the loading overlay while syncing and then an alert if
    /// syncing fails.
    @MainActor
    func test_perform_syncNow_error() async throws {
        let error = URLError(.timedOut)
        settingsRepository.fetchSyncResult = .failure(error)

        await subject.perform(.syncNow)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.syncing)])
        XCTAssertTrue(settingsRepository.fetchSyncCalled)

        let errorAlertWithRetry = try XCTUnwrap(coordinator.errorAlertsWithRetryShown.last)
        XCTAssertEqual(errorAlertWithRetry.error as? URLError, error)

        // Tapping the try again button the alert should attempt the call again.
        settingsRepository.fetchSyncCalled = false
        await errorAlertWithRetry.retry()
        XCTAssertTrue(settingsRepository.fetchSyncCalled)
    }

    /// `receive(_:)` with `.clearClipboardValueChanged` updates the value in the state and the repository.
    @MainActor
    func test_receive_clearClipboardValueChanged() {
        subject.receive(.clearClipboardValueChanged(.twentySeconds))

        XCTAssertEqual(subject.state.clearClipboardValue, .twentySeconds)
        XCTAssertEqual(settingsRepository.clearClipboardValue, .twentySeconds)
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    @MainActor
    func test_receive_toastShown() {
        let toast = Toast(title: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `isAllowSyncOnRefreshToggleOn` updates the value in the state and records an error if it
    /// failed to update the cached data.
    @MainActor
    func test_receive_toggleAllowSyncOnRefresh_error() {
        settingsRepository.allowSyncOnRefreshResult = .failure(BitwardenTestError.example)

        subject.receive(.toggleAllowSyncOnRefresh(true))

        XCTAssertFalse(subject.state.isAllowSyncOnRefreshToggleOn)
        waitFor { self.errorReporter.errors.isEmpty == false }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `receive(_:)` with `isAllowSyncOnRefreshToggleOn` updates the value in the state and the repository.
    @MainActor
    func test_receive_toggleAllowSyncOnRefresh_success() {
        XCTAssertFalse(subject.state.isAllowSyncOnRefreshToggleOn)

        subject.receive(.toggleAllowSyncOnRefresh(true))

        waitFor { self.subject.state.isAllowSyncOnRefreshToggleOn == true }
        XCTAssertTrue(settingsRepository.allowSyncOnRefresh)
        XCTAssertTrue(subject.state.isAllowSyncOnRefreshToggleOn)
    }

    /// `receive(_:)` with `toggleConnectToWatch` updates the value in the state and records an error if it
    /// failed to update the cached data.
    @MainActor
    func test_receive_toggleConnectToWatch_error() {
        settingsRepository.connectToWatchResult = .failure(BitwardenTestError.example)

        subject.receive(.toggleConnectToWatch(true))

        XCTAssertFalse(subject.state.isConnectToWatchToggleOn)
        waitFor { self.errorReporter.errors.isEmpty == false }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `receive(_:)` with `toggleConnectToWatch` updates the value in the state and the repository
    @MainActor
    func test_receive_toggleConnectToWatch_success() {
        XCTAssertFalse(subject.state.isConnectToWatchToggleOn)

        let task = Task {
            subject.receive(.toggleConnectToWatch(true))
        }

        waitFor(subject.state.isConnectToWatchToggleOn)
        task.cancel()
        XCTAssertTrue(settingsRepository.connectToWatch)
        XCTAssertTrue(subject.state.isConnectToWatchToggleOn)
    }

    /// `receive(_:)` with `toggleSiriAndShortcutsAccessToggleOn` updates the value in the state
    /// and records an error if it failed to update the cached data.
    @MainActor
    func test_receive_toggleSiriAndShortcutsAccessToggleOn_error() {
        settingsRepository.siriAndShortcutsAccessResult = .failure(BitwardenTestError.example)

        subject.receive(.toggleSiriAndShortcutsAccessToggleOn(true))

        XCTAssertFalse(subject.state.isSiriAndShortcutsAccessToggleOn)
        waitFor { self.errorReporter.errors.isEmpty == false }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `receive(_:)` with `toggleSiriAndShortcutsAccessToggleOn` updates the value in the state and the repository
    @MainActor
    func test_receive_toggleSiriAndShortcutsAccessToggleOn_success() {
        XCTAssertFalse(subject.state.isSiriAndShortcutsAccessToggleOn)

        let task = Task {
            subject.receive(.toggleSiriAndShortcutsAccessToggleOn(true))
        }

        waitFor(subject.state.isSiriAndShortcutsAccessToggleOn)
        task.cancel()
        XCTAssertTrue(settingsRepository.siriAndShortcutsAccess)
        XCTAssertTrue(subject.state.isSiriAndShortcutsAccessToggleOn)
    }
}
