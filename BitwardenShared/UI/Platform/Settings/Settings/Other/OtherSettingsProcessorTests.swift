import XCTest

@testable import BitwardenShared

class OtherSettingsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var errorReporter: MockErrorReporter!
    var settingsRepository: MockSettingsRepository!
    var subject: OtherSettingsProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        errorReporter = MockErrorReporter()
        settingsRepository = MockSettingsRepository()
        subject = OtherSettingsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                errorReporter: errorReporter,
                settingsRepository: settingsRepository
            ),
            state: OtherSettingsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        settingsRepository = nil
        subject = nil
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
    func test_perform_loadInitialValues_success() async {
        settingsRepository.allowSyncOnRefresh = true
        settingsRepository.clearClipboardValue = .thirtySeconds
        settingsRepository.connectToWatch = true

        await subject.perform(.loadInitialValues)

        XCTAssertEqual(subject.state.clearClipboardValue, .thirtySeconds)
        XCTAssertTrue(subject.state.isAllowSyncOnRefreshToggleOn)
        XCTAssertTrue(subject.state.isConnectToWatchToggleOn)
    }

    /// `perform(_:)` with `.streamLastSyncTime` updates the state's last sync time whenever it changes.
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
    func test_perform_syncNow() async {
        await subject.perform(.syncNow)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.syncing)])
        XCTAssertTrue(settingsRepository.fetchSyncCalled)
        XCTAssertEqual(subject.state.toast?.text, Localizations.syncingComplete)
    }

    /// `perform(_:)` with `.syncNow` shows the loading overlay while syncing and then an alert if
    /// syncing fails.
    func test_perform_syncNow_error() async throws {
        settingsRepository.fetchSyncResult = .failure(URLError(.timedOut))

        await subject.perform(.syncNow)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.syncing)])
        XCTAssertTrue(settingsRepository.fetchSyncCalled)

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(alert, .networkResponseError(URLError(.timedOut)))

        // Tapping the try again button the alert should attempt the call again.
        settingsRepository.fetchSyncCalled = false
        let tryAgainAction = try XCTUnwrap(alert.alertActions.first)
        await tryAgainAction.handler?(tryAgainAction, [])
        XCTAssertTrue(settingsRepository.fetchSyncCalled)
    }

    /// `receive(_:)` with `.clearClipboardValueChanged` updates the value in the state and the repository.
    func test_receive_clearClipboardValueChanged() {
        subject.receive(.clearClipboardValueChanged(.twentySeconds))

        XCTAssertEqual(subject.state.clearClipboardValue, .twentySeconds)
        XCTAssertEqual(settingsRepository.clearClipboardValue, .twentySeconds)
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// `receive(_:)` with `isAllowSyncOnRefreshToggleOn` updates the value in the state and records an error if it
    /// failed to update the cached data.
    func test_receive_toggleAllowSyncOnRefresh_error() {
        settingsRepository.allowSyncOnRefreshResult = .failure(BitwardenTestError.example)

        subject.receive(.toggleAllowSyncOnRefresh(true))

        XCTAssertFalse(subject.state.isAllowSyncOnRefreshToggleOn)
        waitFor { self.errorReporter.errors.isEmpty == false }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `receive(_:)` with `isAllowSyncOnRefreshToggleOn` updates the value in the state and the repository.
    func test_receive_toggleAllowSyncOnRefresh_success() {
        XCTAssertFalse(subject.state.isAllowSyncOnRefreshToggleOn)

        subject.receive(.toggleAllowSyncOnRefresh(true))

        waitFor { self.subject.state.isAllowSyncOnRefreshToggleOn == true }
        XCTAssertTrue(settingsRepository.allowSyncOnRefresh)
        XCTAssertTrue(subject.state.isAllowSyncOnRefreshToggleOn)
    }

    /// `receive(_:)` with `toggleConnectToWatch` updates the value in the state and records an error if it
    /// failed to update the cached data.
    func test_receive_toggleConnectToWatch_error() {
        settingsRepository.connectToWatchResult = .failure(BitwardenTestError.example)

        subject.receive(.toggleConnectToWatch(true))

        XCTAssertFalse(subject.state.isConnectToWatchToggleOn)
        waitFor { self.errorReporter.errors.isEmpty == false }
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `receive(_:)` with `toggleConnectToWatch` updates the value in the state and the repository
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
}
