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
        struct SyncError: Error, Equatable {}
        settingsRepository.fetchSyncResult = .failure(SyncError())

        await subject.perform(.syncNow)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.syncing)])
        XCTAssertTrue(settingsRepository.fetchSyncCalled)

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(alert, .defaultAlert(title: Localizations.anErrorHasOccurred))
    }

    /// `receive(_:)` with `.toastShown` updates the state's toast value.
    func test_receive_toastShown() {
        let toast = Toast(text: "toast!")
        subject.receive(.toastShown(toast))
        XCTAssertEqual(subject.state.toast, toast)

        subject.receive(.toastShown(nil))
        XCTAssertNil(subject.state.toast)
    }

    /// Toggling allow sync on refresh is reflected in the state.
    func test_toggleAllowSyncOnRefresh() {
        XCTAssertFalse(subject.state.isAllowSyncOnRefreshToggleOn)

        subject.receive(.toggleAllowSyncOnRefresh(true))

        XCTAssertTrue(subject.state.isAllowSyncOnRefreshToggleOn)
    }

    /// Toggling connect to watch is reflected in the state.
    func test_toggleConnectToWatch() {
        XCTAssertFalse(subject.state.isConnectToWatchToggleOn)

        subject.receive(.toggleConnectToWatch(true))

        XCTAssertTrue(subject.state.isConnectToWatchToggleOn)
    }
}
