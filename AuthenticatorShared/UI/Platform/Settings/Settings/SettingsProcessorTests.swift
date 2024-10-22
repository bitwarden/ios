import XCTest

@testable import AuthenticatorShared

class SettingsProcessorTests: AuthenticatorTestCase {
    // MARK: Properties

    var configService: MockConfigService!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var subject: SettingsProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        configService = MockConfigService()
        coordinator = MockCoordinator()
        subject = SettingsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                configService: configService
            ),
            state: SettingsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// Performing `.loadData` with the password manager sync disabled sets
    /// `state.shouldShowSyncButton` to `false`.
    func test_perform_loadData_syncDisabled() async throws {
        configService.featureFlagsBool[.enablePasswordManagerSync] = false
        await subject.perform(.loadData)

        XCTAssertFalse(subject.state.shouldShowSyncButton)
    }

    /// Performing `.loadData` with the password manager sync enabled sets
    /// `state.shouldShowSyncButton` to `true`.
    func test_perform_loadData_syncEnabled() async throws {
        configService.featureFlagsBool[.enablePasswordManagerSync] = true
        await subject.perform(.loadData)

        XCTAssertTrue(subject.state.shouldShowSyncButton)
    }

    /// Receiving `.backupTapped` shows an alert for the backup information.
    func test_receive_backupTapped() async throws {
        subject.receive(.backupTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.learnMore)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.backupInformation)
    }

    /// Receiving `.exportItemsTapped` navigates to the export vault screen.
    func test_receive_exportVaultTapped() {
        subject.receive(.exportItemsTapped)

        XCTAssertEqual(coordinator.routes.last, .exportItems)
    }

    /// Receiving `.syncWithBitwardenAppTapped` adds the Password Manager settings URL to the state to
    /// navigate the user to the PM app's settings.
    func test_receive_syncWithBitwardenAppTapped() {
        subject.receive(.syncWithBitwardenAppTapped)

        XCTAssertEqual(subject.state.url, ExternalLinksConstants.passwordManagerSettings)
    }
}
