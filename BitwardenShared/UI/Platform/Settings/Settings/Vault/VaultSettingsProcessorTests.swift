import XCTest

@testable import BitwardenShared

class VaultSettingsProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var environmentService: MockEnvironmentService!
    var subject: VaultSettingsProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
        environmentService = MockEnvironmentService()

        subject = VaultSettingsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                environmentService: environmentService
            ),
            state: VaultSettingsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// `receive(_:)` with `.clearUrl` clears the URL in the state.
    func test_receive_clearImportItemsUrl() {
        subject.state.url = .example
        subject.receive(.clearUrl)

        XCTAssertNil(subject.state.url)
    }

    /// Receiving `.exportVaultTapped` navigates to the export vault screen.
    func test_receive_exportVaultTapped() {
        subject.receive(.exportVaultTapped)

        XCTAssertEqual(coordinator.routes.last, .exportVault)
    }

    /// `receive(_:)` with  `.foldersTapped` navigates to the folders screen.
    func test_receive_foldersTapped() {
        subject.receive(.foldersTapped)

        XCTAssertEqual(coordinator.routes.last, .folders)
    }

    /// `receive(_:)` with `.importItemsTapped` shows an alert for navigating to the import items website.
    ///  When `Continue` is tapped on the alert, sets the URL to open in the state
    func test_receive_importItemsTapped() async throws {
        subject.receive(.importItemsTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.continue)
        XCTAssertEqual(subject.state.url, environmentService.importItemsURL)
    }
}
