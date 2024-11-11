import XCTest

@testable import AuthenticatorShared

class SettingsProcessorTests: AuthenticatorTestCase {
    // MARK: Properties

    var application: MockApplication!
    var appSettingsStore: MockAppSettingsStore!
    var authItemRepository: MockAuthenticatorItemRepository!
    var configService: MockConfigService!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var subject: SettingsProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        application = MockApplication()
        appSettingsStore = MockAppSettingsStore()
        authItemRepository = MockAuthenticatorItemRepository()
        configService = MockConfigService()
        coordinator = MockCoordinator()
        subject = SettingsProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                application: application,
                appSettingsStore: appSettingsStore,
                authenticatorItemRepository: authItemRepository,
                configService: configService
            ),
            state: SettingsState()
        )
    }

    override func tearDown() {
        super.tearDown()

        application = nil
        appSettingsStore = nil
        authItemRepository = nil
        configService = nil
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

    /// Performing `.loadData` sets the 'defaultSaveOption' to the current value in 'AppSettingsStore'.
    func test_perform_loadData_defaultSaveOption() async throws {
        configService.featureFlagsBool[.enablePasswordManagerSync] = true
        appSettingsStore.defaultSaveOption = .saveToBitwarden
        await subject.perform(.loadData)

        XCTAssertEqual(subject.state.defaultSaveOption, .saveToBitwarden)
    }

    /// Performing `.loadData` sets the sync related flags correctly when the feature flag is
    /// disabled and the sync is off.
    func test_perform_loadData_syncFlagDisabled_syncOff() async throws {
        configService.featureFlagsBool[.enablePasswordManagerSync] = false
        authItemRepository.pmSyncEnabled = false
        await subject.perform(.loadData)

        XCTAssertFalse(subject.state.shouldShowDefaultSaveOption)
        XCTAssertFalse(subject.state.shouldShowSyncButton)
    }

    /// Performing `.loadData` sets the sync related flags correctly when the feature flag is
    /// enabled and the sync is off.
    func test_perform_loadData_syncFlagEnabled_syncOff() async throws {
        configService.featureFlagsBool[.enablePasswordManagerSync] = true
        authItemRepository.pmSyncEnabled = false
        await subject.perform(.loadData)

        XCTAssertFalse(subject.state.shouldShowDefaultSaveOption)
        XCTAssertTrue(subject.state.shouldShowSyncButton)
    }

    /// Performing `.loadData` sets the sync related flags correctly when the feature flag is
    /// disabled and the sync is on.
    func test_perform_loadData_syncFlagDisabled_syncOn() async throws {
        configService.featureFlagsBool[.enablePasswordManagerSync] = false
        authItemRepository.pmSyncEnabled = true
        await subject.perform(.loadData)

        XCTAssertFalse(subject.state.shouldShowDefaultSaveOption)
        XCTAssertFalse(subject.state.shouldShowSyncButton)
    }

    /// Performing `.loadData` sets the sync related flags correctly when the feature flag is
    /// enabled and the sync is on.
    func test_perform_loadData_syncFlagEnabled_syncOn() async throws {
        configService.featureFlagsBool[.enablePasswordManagerSync] = true
        authItemRepository.pmSyncEnabled = true
        await subject.perform(.loadData)

        XCTAssertTrue(subject.state.shouldShowDefaultSaveOption)
        XCTAssertTrue(subject.state.shouldShowSyncButton)
    }

    /// Receiving `.backupTapped` shows an alert for the backup information.
    func test_receive_backupTapped() async throws {
        subject.receive(.backupTapped)

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.learnMore)
        XCTAssertEqual(subject.state.url, ExternalLinksConstants.backupInformation)
    }

    /// Receiving `.defaultSaveChanged` updates the user's `defaultSaveOption` app setting.
    func test_receive_defaultSaveChanged() {
        subject.state.defaultSaveOption = .none
        subject.receive(.defaultSaveChanged(.saveHere))

        XCTAssertEqual(appSettingsStore.defaultSaveOption, .saveHere)
        XCTAssertEqual(subject.state.defaultSaveOption, .saveHere)
    }

    /// Receiving `.exportItemsTapped` navigates to the export vault screen.
    func test_receive_exportVaultTapped() {
        subject.receive(.exportItemsTapped)

        XCTAssertEqual(coordinator.routes.last, .exportItems)
    }

    /// Receiving `.syncWithBitwardenAppTapped` adds the Password Manager settings URL to the state to
    /// navigate the user to the PM app's settings.
    func test_receive_syncWithBitwardenAppTapped_installed() {
        application.canOpenUrlResponse = true
        subject.receive(.syncWithBitwardenAppTapped)

        XCTAssertEqual(subject.state.url, ExternalLinksConstants.passwordManagerSettings)
    }

    /// Receiving `.syncWithBitwardenAppTapped` adds the Password Manager settings App Store URL to
    /// the state to navigate the user to the App Store when the PM app is not installed..
    func test_receive_syncWithBitwardenAppTapped_notInstalled() {
        application.canOpenUrlResponse = false
        subject.receive(.syncWithBitwardenAppTapped)

        XCTAssertEqual(subject.state.url, ExternalLinksConstants.passwordManagerLink)
    }
}
