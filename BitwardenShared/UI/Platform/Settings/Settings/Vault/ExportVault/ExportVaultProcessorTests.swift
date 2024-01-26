import XCTest

@testable import BitwardenShared

class ExportVaultProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<SettingsRoute>!
    var errorReporter: MockErrorReporter!
    var policyService: MockPolicyService!
    var settingsRepository: MockSettingsRepository!
    var subject: ExportVaultProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        coordinator = MockCoordinator<SettingsRoute>()
        errorReporter = MockErrorReporter()
        policyService = MockPolicyService()
        settingsRepository = MockSettingsRepository()
        let services = ServiceContainer.withMocks(
            errorReporter: errorReporter,
            policyService: policyService,
            settingsRepository: settingsRepository
        )

        subject = ExportVaultProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services
        )
    }

    override func tearDown() {
        super.tearDown()

        coordinator = nil
        errorReporter = nil
        policyService = nil
        settingsRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// Test that an alert is displayed if the user tries to export with an invalid password.
    func test_invalidPassword() async throws {
        settingsRepository.validatePasswordResult = .success(false)

        subject.receive(.exportVaultTapped)
        let exportAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await exportAction.handler?(exportAction, [])

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.invalidMasterPassword))
    }

    /// Test that an error is recorded if there was an error validating the password.
    func test_invalidPassword_error() async throws {
        settingsRepository.validatePasswordResult = .failure(BitwardenTestError.example)

        subject.receive(.exportVaultTapped)
        let exportAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await exportAction.handler?(exportAction, [])

        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, .example)
    }

    /// `loadData` loads the initial data for the view.
    func test_perform_loadData() async {
        await subject.perform(.loadData)
        XCTAssertFalse(subject.state.disableIndividualVaultExport)

        policyService.policyAppliesToUserResult[.disablePersonalVaultExport] = true
        await subject.perform(.loadData)
        XCTAssertTrue(subject.state.disableIndividualVaultExport)
    }

    /// `.receive()` with `.dismiss` dismisses the view.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `.receive()` with  `.exportVaultTapped` shows the confirm alert for encrypted formats.
    func test_receive_exportVaultTapped_encrypted() {
        subject.state.fileFormat = .jsonEncrypted
        subject.receive(.exportVaultTapped)

        // Confirm that the correct alert is displayed.
        XCTAssertEqual(coordinator.alertShown.last, .confirmExportVault(encrypted: true, action: {}))
    }

    /// `.receive()` with `.exportVaultTapped` shows the confirm alert for unencrypted formats.
    func test_receive_exportVaultTapped_unencrypted() {
        subject.state.fileFormat = .json
        subject.receive(.exportVaultTapped)

        // Confirm that the correct alert is displayed.
        XCTAssertEqual(coordinator.alertShown.last, .confirmExportVault(encrypted: false, action: {}))
    }

    /// `.receive()` with `.fileFormatTypeChanged()` updates the file format.
    func test_receive_fileFormatTypeChanged() {
        subject.receive(.fileFormatTypeChanged(.csv))

        XCTAssertEqual(subject.state.fileFormat, .csv)
    }

    /// `.receive()` with `.passwordTextChanged()` updates the password text.
    func test_receive_passwordTextChanged() {
        subject.receive(.passwordTextChanged("password"))

        XCTAssertEqual(subject.state.passwordText, "password")
    }

    /// `.receive()` with `.togglePasswordVisibility()` toggles the password visibility.
    func test_receive_togglePasswordVisibility() {
        subject.receive(.togglePasswordVisibility(true))
        XCTAssertTrue(subject.state.isPasswordVisible)

        subject.receive(.togglePasswordVisibility(false))
        XCTAssertFalse(subject.state.isPasswordVisible)
    }
}
