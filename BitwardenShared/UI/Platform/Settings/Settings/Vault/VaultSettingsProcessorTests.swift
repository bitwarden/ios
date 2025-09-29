import BitwardenKitMocks
import BitwardenResources
import XCTest

@testable import BitwardenShared

class VaultSettingsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: VaultSettingsProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        subject = VaultSettingsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                environmentService: environmentService,
                errorReporter: errorReporter,
                stateService: stateService
            ),
            state: VaultSettingsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        environmentService = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `perform(_:)` with `.dismissImportLoginsActionCard` sets the user's import logins setup
    /// progress to complete.
    @MainActor
    func test_perform_dismissImportLoginsActionCard() async {
        stateService.activeAccount = .fixture()
        stateService.accountSetupImportLogins["1"] = .setUpLater

        await subject.perform(.dismissImportLoginsActionCard)

        XCTAssertEqual(stateService.accountSetupImportLogins["1"], .complete)
    }

    /// `perform(_:)` with `.dismissImportLoginsActionCard` logs an error and shows an alert if an
    /// error occurs.
    @MainActor
    func test_perform_dismissImportLoginsActionCard_error() async {
        await subject.perform(.dismissImportLoginsActionCard)

        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(error: StateServiceError.noActiveAccount)])
        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `perform(_:)` with `.streamSettingsBadge` updates the state's badge state whenever it changes.
    @MainActor
    func test_perform_streamSettingsBadge() {
        stateService.activeAccount = .fixture()

        let task = Task {
            await subject.perform(.streamSettingsBadge)
        }
        defer { task.cancel() }

        let badgeState = SettingsBadgeState.fixture(importLoginsSetupProgress: .setUpLater)
        stateService.settingsBadgeSubject.send(badgeState)
        waitFor { subject.state.badgeState == badgeState }

        XCTAssertEqual(subject.state.badgeState, badgeState)
    }

    /// `perform(_:)` with `.streamSettingsBadge` logs an error if streaming the settings badge state fails.
    @MainActor
    func test_perform_streamSettingsBadge_error() async {
        await subject.perform(.streamSettingsBadge)

        XCTAssertEqual(errorReporter.errors as? [StateServiceError], [.noActiveAccount])
    }

    /// `receive(_:)` with `.clearUrl` clears the URL in the state.
    @MainActor
    func test_receive_clearImportItemsUrl() {
        subject.state.url = .example
        subject.receive(.clearUrl)

        XCTAssertNil(subject.state.url)
    }

    /// Receiving `.exportVaultTapped` navigates to the export vault screen.
    @MainActor
    func test_receive_exportVaultTapped() {
        subject.receive(.exportVaultTapped)

        XCTAssertEqual(coordinator.routes.last, .exportVault)
    }

    /// `receive(_:)` with  `.foldersTapped` navigates to the folders screen.
    @MainActor
    func test_receive_foldersTapped() {
        subject.receive(.foldersTapped)

        XCTAssertEqual(coordinator.routes.last, .folders)
    }

    /// `receive(_:)` with `.importItemsTapped` shows an alert for navigating to the import items website.
    ///  When `Continue` is tapped on the alert, sets the URL to open in the state
    @MainActor
    func test_receive_importItemsTapped() async throws {
        subject.receive(.importItemsTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.continue)
        XCTAssertEqual(subject.state.url, environmentService.importItemsURL)
    }

    /// `receive(_:)` with  `.showImportLogins` navigates to the import logins screen.
    @MainActor
    func test_receive_showImportLogins() {
        subject.receive(.showImportLogins)

        XCTAssertEqual(coordinator.routes.last, .importLogins)
    }
}
