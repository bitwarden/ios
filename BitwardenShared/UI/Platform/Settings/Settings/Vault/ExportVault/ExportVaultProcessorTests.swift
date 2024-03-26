import XCTest

@testable import BitwardenShared

class ExportVaultProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<SettingsRoute, SettingsEvent>!
    var errorReporter: MockErrorReporter!
    var exportService: MockExportVaultService!
    var policyService: MockPolicyService!
    var subject: ExportVaultProcessor!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        authRepository = MockAuthRepository()
        coordinator = MockCoordinator<SettingsRoute, SettingsEvent>()
        errorReporter = MockErrorReporter()
        exportService = MockExportVaultService()
        policyService = MockPolicyService()
        let services = ServiceContainer.withMocks(
            authRepository: authRepository,
            errorReporter: errorReporter,
            exportVaultService: exportService,
            policyService: policyService
        )

        subject = ExportVaultProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: services
        )
    }

    override func tearDown() {
        super.tearDown()

        authRepository = nil
        coordinator = nil
        errorReporter = nil
        exportService = nil
        policyService = nil
        subject = nil
    }

    // MARK: Tests

    /// Test that an alert is displayed if the user tries to export with an invalid password.
    func test_invalidPassword() async throws {
        authRepository.validatePasswordResult = .success(false)
        subject.state.masterPasswordText = "password"

        subject.receive(.exportVaultTapped)
        let exportAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        await exportAction.handler?(exportAction, [])

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.invalidMasterPassword))
    }

    /// Test that an error is recorded if there was an error validating the password.
    func test_invalidPassword_error() async throws {
        authRepository.validatePasswordResult = .failure(BitwardenTestError.example)
        subject.state.masterPasswordText = "password"

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

    /// `.receive()` with `.dismiss` dismisses the view and clears any files.
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertTrue(exportService.didClearFiles)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `.receive()` with  `.exportVaultTapped` shows the confirm alert for encrypted formats and
    /// exports the vault.
    func test_receive_exportVaultTapped_encrypted() throws {
        let testURL = URL(string: "www.bitwarden.com")!
        exportService.exportVaultContentResult = .success("")
        exportService.writeToFileResult = .success(testURL)
        subject.state.fileFormat = .jsonEncrypted
        subject.state.filePasswordText = "file password"
        subject.state.filePasswordConfirmationText = "file password"
        subject.state.masterPasswordText = "password"
        subject.receive(.exportVaultTapped)

        // Confirm that the correct alert is displayed.
        XCTAssertEqual(coordinator.alertShown.last, .confirmExportVault(encrypted: true, action: {}))

        let exportAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        let task = Task {
            await exportAction.handler?(exportAction, [])
        }
        waitFor(!coordinator.routes.isEmpty)
        task.cancel()
        XCTAssertEqual(exportService.exportVaultContentsFormat, .encryptedJson(password: "file password"))
        XCTAssertEqual(coordinator.routes.last, .shareExportedVault(testURL))
    }

    /// `.receive()` with  `.exportVaultTapped` logs an error on export failure.
    func test_receive_exportVaultTapped_encrypted_error() throws {
        exportService.exportVaultContentResult = .failure(BitwardenTestError.example)
        subject.state.fileFormat = .jsonEncrypted
        subject.state.filePasswordText = "file password"
        subject.state.filePasswordConfirmationText = "file password"
        subject.state.masterPasswordText = "password"
        subject.receive(.exportVaultTapped)

        // Select the alert action to export.
        let exportAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        let task = Task {
            await exportAction.handler?(exportAction, [])
        }
        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()
        XCTAssertEqual(errorReporter.errors.first as? BitwardenTestError, .example)
    }

    /// `.receive()` with  `.exportVaultTapped` shows an alert if the file password fields don't match.
    func test_receive_exportVaultTapped_encrypted_filePasswordMismatch() {
        subject.state.fileFormat = .jsonEncrypted
        subject.state.filePasswordText = "filePassword"
        subject.state.filePasswordConfirmationText = "not the file password"

        subject.receive(.exportVaultTapped)

        XCTAssertEqual(coordinator.alertShown.last, .passwordsDontMatch)
    }

    /// `.receive()` with  `.exportVaultTapped` shows an alert if the file password is missing.
    func test_receive_exportVaultTapped_encrypted_missingFilePassword() {
        subject.state.fileFormat = .jsonEncrypted

        subject.receive(.exportVaultTapped)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .inputValidationAlert(
                error: InputValidationError(
                    message: Localizations.validationFieldRequired(Localizations.filePassword)
                )
            )
        )
    }

    /// `.receive()` with  `.exportVaultTapped` shows an alert if the file password confirmation is missing.
    func test_receive_exportVaultTapped_encrypted_missingFilePasswordConfirmation() {
        subject.state.fileFormat = .jsonEncrypted
        subject.state.filePasswordText = "file password"

        subject.receive(.exportVaultTapped)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .inputValidationAlert(
                error: InputValidationError(
                    message: Localizations.validationFieldRequired(Localizations.confirmFilePassword)
                )
            )
        )
    }

    /// `.receive()` with  `.exportVaultTapped` shows an alert if the master password is missing.
    func test_receive_exportVaultTapped_missingMasterPassword() {
        subject.receive(.exportVaultTapped)

        XCTAssertEqual(
            coordinator.alertShown.last,
            .inputValidationAlert(
                error: InputValidationError(
                    message: Localizations.validationFieldRequired(Localizations.masterPassword)
                )
            )
        )
    }

    /// `.receive()` with `.exportVaultTapped` shows the confirm alert for unencrypted formats.
    func test_receive_exportVaultTapped_unencrypted() {
        subject.state.fileFormat = .json
        subject.state.masterPasswordText = "password"
        subject.receive(.exportVaultTapped)

        // Confirm that the correct alert is displayed.
        XCTAssertEqual(coordinator.alertShown.last, .confirmExportVault(encrypted: false, action: {}))
    }

    /// `.receive()` with  `.exportVaultTapped` logs an error on export failure.
    func test_receive_exportVaultTapped_unencrypted_error() throws {
        exportService.exportVaultContentResult = .failure(BitwardenTestError.example)
        subject.state.fileFormat = .csv
        subject.state.masterPasswordText = "password"
        subject.receive(.exportVaultTapped)

        // Select the alert action to export.
        let exportAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        let task = Task {
            await exportAction.handler?(exportAction, [])
        }
        waitFor(!errorReporter.errors.isEmpty)
        task.cancel()
        XCTAssertEqual(errorReporter.errors.first as? BitwardenTestError, .example)
    }

    /// `.receive()` with  `.exportVaultTapped` passes a file url to the coordinator on success.
    func test_receive_exportVaultTapped_unencrypted_success() throws {
        let testURL = URL(string: "www.bitwarden.com")!
        exportService.exportVaultContentResult = .success("")
        exportService.writeToFileResult = .success(testURL)
        subject.state.fileFormat = .json
        subject.state.masterPasswordText = "password"
        subject.receive(.exportVaultTapped)

        // Select the alert action to export.
        let exportAction = try XCTUnwrap(coordinator.alertShown.last?.alertActions.first)
        let task = Task {
            await exportAction.handler?(exportAction, [])
        }
        waitFor(!coordinator.routes.isEmpty)
        task.cancel()
        XCTAssertEqual(coordinator.routes.last, .shareExportedVault(testURL))
    }

    /// `.receive()` with  `.exportVaultTapped` clears the user's master password after exporting
    /// the vault successfully.
    func test_receive_exportVaultTapped_success_clearsMasterPassword() async throws {
        let testURL = URL(string: "www.bitwarden.com")!
        exportService.exportVaultContentResult = .success("")
        exportService.writeToFileResult = .success(testURL)
        subject.state.fileFormat = .json
        subject.state.masterPasswordText = "password"

        subject.receive(.exportVaultTapped)

        XCTAssertEqual(coordinator.alertShown.last, .confirmExportVault(encrypted: false, action: {}))
        try await coordinator.alertShown.last?.tapAction(title: Localizations.exportVault)

        XCTAssertEqual(coordinator.routes.last, .shareExportedVault(testURL))
        XCTAssertTrue(subject.state.masterPasswordText.isEmpty)
    }

    /// `.receive()` with `.fileFormatTypeChanged()` updates the file format.
    func test_receive_fileFormatTypeChanged() {
        subject.receive(.fileFormatTypeChanged(.csv))

        XCTAssertEqual(subject.state.fileFormat, .csv)
    }

    /// `.receive()` with `.filePasswordTextChanged()` updates the file password text.
    func test_receive_filePasswordTextChanged() {
        subject.receive(.filePasswordTextChanged("file password"))

        XCTAssertEqual(subject.state.filePasswordText, "file password")
    }

    /// `.receive()` with `.filePasswordTextChanged()` updates the password strength.
    func test_receive_filePasswordTextChanged_updatesPasswordStrength() {
        authRepository.passwordStrengthResult = 1
        subject.receive(.filePasswordTextChanged("file"))
        waitFor(subject.state.filePasswordStrengthScore == 1)
        XCTAssertEqual(authRepository.passwordStrengthPassword, "file")
        XCTAssertEqual(subject.state.filePasswordStrengthScore, 1)

        authRepository.passwordStrengthResult = 4
        subject.receive(.filePasswordTextChanged("file password"))
        waitFor(subject.state.filePasswordStrengthScore == 4)
        XCTAssertEqual(authRepository.passwordStrengthPassword, "file password")
        XCTAssertEqual(subject.state.filePasswordStrengthScore, 4)

        subject.receive(.filePasswordTextChanged(""))
        XCTAssertNil(subject.state.filePasswordStrengthScore)
    }

    /// `.receive()` with `.filePasswordConfirmationTextChanged()` updates the file password confirmation text.
    func test_receive_filePasswordConfirmationTextChanged() {
        subject.receive(.filePasswordConfirmationTextChanged("file password"))

        XCTAssertEqual(subject.state.filePasswordConfirmationText, "file password")
    }

    /// `.receive()` with `.masterPasswordTextChanged()` updates the master password text.
    func test_receive_masterPasswordTextChanged() {
        subject.receive(.masterPasswordTextChanged("password"))

        XCTAssertEqual(subject.state.masterPasswordText, "password")
    }

    /// `.receive()` with `.toggleFilePasswordVisibility()` toggles the file password visibility.
    func test_receive_toggleFilePasswordVisibility() {
        subject.receive(.toggleFilePasswordVisibility(true))
        XCTAssertTrue(subject.state.isFilePasswordVisible)

        subject.receive(.toggleFilePasswordVisibility(false))
        XCTAssertFalse(subject.state.isFilePasswordVisible)
    }

    /// `.receive()` with `.toggleMasterPasswordVisibility()` toggles the master password visibility.
    func test_receive_toggleMasterPasswordVisibility() {
        subject.receive(.toggleMasterPasswordVisibility(true))
        XCTAssertTrue(subject.state.isMasterPasswordVisible)

        subject.receive(.toggleMasterPasswordVisibility(false))
        XCTAssertFalse(subject.state.isMasterPasswordVisible)
    }
}
