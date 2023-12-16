import XCTest

@testable import BitwardenShared

class OtherSettingsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var settingsRepository: MockSettingsRepository!
    var subject: OtherSettingsProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        settingsRepository = MockSettingsRepository()
        subject = OtherSettingsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                settingsRepository: settingsRepository
            ),
            state: OtherSettingsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        settingsRepository = nil
        subject = nil
    }

    // MARK: Tests

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
