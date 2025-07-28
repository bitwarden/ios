import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import TestHelpers
import XCTest

@testable import BitwardenShared

class ExportVaultProcessorTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
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
    @MainActor
    func test_invalidPassword() async throws {
        authRepository.validatePasswordResult = .success(false)
        subject.state.masterPasswordOrOtpText = "password"

        await subject.perform(.exportVaultTapped)

        let confirmationAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await confirmationAlert.tapAction(title: Localizations.exportVault)

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.invalidMasterPassword))
    }

    /// Test that an error is recorded if there was an error validating the password.
    @MainActor
    func test_invalidPassword_error() async throws {
        authRepository.validatePasswordResult = .failure(BitwardenTestError.example)
        subject.state.masterPasswordOrOtpText = "password"

        await subject.perform(.exportVaultTapped)

        let confirmationAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await confirmationAlert.tapAction(title: Localizations.exportVault)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
    }

    /// `loadData` loads the initial data for the view.
    @MainActor
    func test_perform_loadData() async {
        await subject.perform(.loadData)
        XCTAssertFalse(subject.state.disableIndividualVaultExport)

        policyService.policyAppliesToUserResult[.disablePersonalVaultExport] = true
        await subject.perform(.loadData)
        XCTAssertTrue(subject.state.disableIndividualVaultExport)
    }

    /// `perform()` with `.sendCodeTapped` requests an OTP code for the user.
    @MainActor
    func test_perform_sendCodeTapped() async {
        await subject.perform(.sendCodeTapped)

        XCTAssertFalse(coordinator.isLoadingOverlayShowing)
        XCTAssertEqual(coordinator.loadingOverlaysShown, [LoadingOverlayState(title: Localizations.sendingCode)])
        XCTAssertTrue(authRepository.requestOtpCalled)
        XCTAssertTrue(subject.state.isSendCodeButtonDisabled)
        XCTAssertEqual(subject.state.toast, Toast(title: Localizations.codeSent))
    }

    /// `perform()` with `.sendCodeTapped` records an error and displays an alert if requesting the
    /// OTP code fails.
    @MainActor
    func test_perform_sendCodeTapped_error() async {
        authRepository.requestOtpResult = .failure(BitwardenTestError.example)

        await subject.perform(.sendCodeTapped)

        XCTAssertEqual(coordinator.errorAlertsShown as? [BitwardenTestError], [.example])
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `.receive()` with `.dismiss` dismisses the view and clears any files.
    @MainActor
    func test_receive_dismiss() {
        subject.receive(.dismiss)

        XCTAssertTrue(exportService.didClearFiles)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `.receive()` with  `.exportVaultTapped` shows the confirm alert for encrypted formats and
    /// exports the vault.
    @MainActor
    func test_receive_exportVaultTapped_encrypted() async throws {
        let testURL = URL(string: "www.bitwarden.com")!
        exportService.exportVaultContentResult = .success("")
        exportService.writeToFileResult = .success(testURL)
        subject.state.fileFormat = .jsonEncrypted
        subject.state.filePasswordText = "file password"
        subject.state.filePasswordConfirmationText = "file password"
        subject.state.masterPasswordOrOtpText = "password"

        await subject.perform(.exportVaultTapped)

        // Confirm that the correct alert is displayed.
        let confirmationAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(confirmationAlert, .confirmExportVault(encrypted: true, action: {}))

        try await confirmationAlert.tapAction(title: Localizations.exportVault)

        XCTAssertEqual(exportService.exportVaultContentsFormat, .encryptedJson(password: "file password"))
        XCTAssertEqual(coordinator.routes.last, .shareURL(testURL))
    }

    /// `.receive()` with  `.exportVaultTapped` logs an error on export failure.
    @MainActor
    func test_receive_exportVaultTapped_encrypted_error() async throws {
        exportService.exportVaultContentResult = .failure(BitwardenTestError.example)
        subject.state.fileFormat = .jsonEncrypted
        subject.state.filePasswordText = "file password"
        subject.state.filePasswordConfirmationText = "file password"
        subject.state.masterPasswordOrOtpText = "password"

        await subject.perform(.exportVaultTapped)

        // Select the alert action to export.
        let confirmationAlert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(confirmationAlert, .confirmExportVault(encrypted: true, action: {}))

        try await confirmationAlert.tapAction(title: Localizations.exportVault)

        XCTAssertEqual(errorReporter.errors.first as? BitwardenTestError, .example)
    }

    /// `.receive()` with  `.exportVaultTapped` shows an alert if the file password fields don't match.
    @MainActor
    func test_receive_exportVaultTapped_encrypted_filePasswordMismatch() async {
        subject.state.fileFormat = .jsonEncrypted
        subject.state.filePasswordText = "filePassword"
        subject.state.filePasswordConfirmationText = "not the file password"

        await subject.perform(.exportVaultTapped)

        XCTAssertEqual(coordinator.alertShown.last, .passwordsDontMatch)
    }

    /// `.receive()` with  `.exportVaultTapped` shows an alert if the file password is missing.
    @MainActor
    func test_receive_exportVaultTapped_encrypted_missingFilePassword() async {
        subject.state.fileFormat = .jsonEncrypted

        await subject.perform(.exportVaultTapped)

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
    @MainActor
    func test_receive_exportVaultTapped_encrypted_missingFilePasswordConfirmation() async {
        subject.state.fileFormat = .jsonEncrypted
        subject.state.filePasswordText = "file password"

        await subject.perform(.exportVaultTapped)

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
    @MainActor
    func test_receive_exportVaultTapped_missingMasterPassword() async {
        await subject.perform(.exportVaultTapped)

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
    @MainActor
    func test_receive_exportVaultTapped_unencrypted() async {
        subject.state.fileFormat = .json
        subject.state.masterPasswordOrOtpText = "password"
        await subject.perform(.exportVaultTapped)

        // Confirm that the correct alert is displayed.
        XCTAssertEqual(coordinator.alertShown.last, .confirmExportVault(encrypted: false, action: {}))
    }

    /// `.receive()` with  `.exportVaultTapped` logs an error on export failure.
    @MainActor
    func test_receive_exportVaultTapped_unencrypted_error() async throws {
        exportService.exportVaultContentResult = .failure(BitwardenTestError.example)
        subject.state.fileFormat = .csv
        subject.state.masterPasswordOrOtpText = "password"

        await subject.perform(.exportVaultTapped)

        // Select the alert action to export.
        let confirmationAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await confirmationAlert.tapAction(title: Localizations.exportVault)

        XCTAssertEqual(errorReporter.errors.first as? BitwardenTestError, .example)
    }

    /// `.receive()` with  `.exportVaultTapped` passes a file url to the coordinator on success.
    @MainActor
    func test_receive_exportVaultTapped_unencrypted_success() async throws {
        let testURL = URL(string: "www.bitwarden.com")!
        exportService.exportVaultContentResult = .success("")
        exportService.writeToFileResult = .success(testURL)
        subject.state.fileFormat = .json
        subject.state.masterPasswordOrOtpText = "password"

        await subject.perform(.exportVaultTapped)

        // Select the alert action to export.
        let confirmationAlert = try XCTUnwrap(coordinator.alertShown.last)
        try await confirmationAlert.tapAction(title: Localizations.exportVault)

        XCTAssertEqual(coordinator.routes.last, .shareURL(testURL))
    }

    /// `.receive()` with  `.exportVaultTapped` clears the user's master password after exporting
    /// the vault successfully.
    @MainActor
    func test_receive_exportVaultTapped_success_clearsPasswords() async throws {
        let testURL = URL(string: "www.bitwarden.com")!
        exportService.exportVaultContentResult = .success("")
        exportService.writeToFileResult = .success(testURL)
        subject.state.fileFormat = .jsonEncrypted
        subject.state.filePasswordText = "file password"
        subject.state.filePasswordConfirmationText = "file password"
        subject.state.masterPasswordOrOtpText = "password"

        await subject.perform(.exportVaultTapped)

        XCTAssertEqual(coordinator.alertShown.last, .confirmExportVault(encrypted: true, action: {}))
        try await coordinator.alertShown.last?.tapAction(title: Localizations.exportVault)

        XCTAssertEqual(coordinator.routes.last, .shareURL(testURL))
        XCTAssertTrue(subject.state.filePasswordText.isEmpty)
        XCTAssertTrue(subject.state.filePasswordConfirmationText.isEmpty)
        XCTAssertNil(subject.state.filePasswordStrengthScore)
        XCTAssertTrue(subject.state.masterPasswordOrOtpText.isEmpty)
    }

    /// `receive()` with `.exportVaultTapped` verifies the user's OTP code and exports the vault if
    /// the user doesn't have a master password.
    @MainActor
    func test_receive_exportVaultTapped_noMasterPassword_success() async throws {
        let testURL = URL(string: "www.bitwarden.com")!
        exportService.exportVaultContentResult = .success("")
        exportService.writeToFileResult = .success(testURL)
        subject.state.hasMasterPassword = false
        subject.state.masterPasswordOrOtpText = "otp"

        await subject.perform(.exportVaultTapped)

        XCTAssertEqual(coordinator.alertShown.last, .confirmExportVault(encrypted: false, action: {}))
        try await coordinator.alertShown.last?.tapAction(title: Localizations.exportVault)

        XCTAssertEqual(coordinator.routes.last, .shareURL(testURL))
        XCTAssertTrue(subject.state.masterPasswordOrOtpText.isEmpty)
        XCTAssertEqual(authRepository.verifyOtpOpt, "otp")
    }

    /// `receive()` with `.exportVaultTapped` displays an alert if OTP verification fails.
    @MainActor
    func test_receive_exportVaultTapped_noMasterPassword_otpVerificationFailure() async throws {
        authRepository.verifyOtpResult = .failure(
            ServerError.error(
                errorResponse: ErrorResponseModel(validationErrors: nil, message: "")
            )
        )
        subject.state.hasMasterPassword = false
        subject.state.masterPasswordOrOtpText = "otp"

        await subject.perform(.exportVaultTapped)

        XCTAssertEqual(coordinator.alertShown.last, .confirmExportVault(encrypted: false, action: {}))
        try await coordinator.alertShown.last?.tapAction(title: Localizations.exportVault)

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.invalidVerificationCode))
        XCTAssertTrue(coordinator.routes.isEmpty)
    }

    /// `.receive()` with `.fileFormatTypeChanged()` updates the file format.
    @MainActor
    func test_receive_fileFormatTypeChanged() {
        subject.receive(.fileFormatTypeChanged(.csv))

        XCTAssertEqual(subject.state.fileFormat, .csv)
    }

    /// `.receive()` with `.filePasswordTextChanged()` updates the file password text.
    @MainActor
    func test_receive_filePasswordTextChanged() {
        subject.receive(.filePasswordTextChanged("file password"))

        XCTAssertEqual(subject.state.filePasswordText, "file password")
    }

    /// `.receive()` with `.filePasswordTextChanged()` updates the password strength.
    @MainActor
    func test_receive_filePasswordTextChanged_updatesPasswordStrength() {
        authRepository.passwordStrengthResult = .success(1)
        subject.receive(.filePasswordTextChanged("file"))
        waitFor(subject.state.filePasswordStrengthScore == 1)
        XCTAssertFalse(authRepository.passwordStrengthIsPreAuth)
        XCTAssertEqual(authRepository.passwordStrengthPassword, "file")

        authRepository.passwordStrengthResult = .success(4)
        subject.receive(.filePasswordTextChanged("file password"))
        waitFor(subject.state.filePasswordStrengthScore == 4)
        XCTAssertFalse(authRepository.passwordStrengthIsPreAuth)
        XCTAssertEqual(authRepository.passwordStrengthPassword, "file password")

        subject.receive(.filePasswordTextChanged(""))
        XCTAssertNil(subject.state.filePasswordStrengthScore)
    }

    /// `receive(_:)` with `.filePasswordTextChanged(_:)` records an error if the `.passwordStrength()` throws.
    @MainActor
    func test_receive_filePasswordTextChanged_updatePasswordStrength_fails() {
        authRepository.passwordStrengthResult = .failure(BitwardenTestError.example)
        subject.receive(.filePasswordTextChanged("T"))
        waitFor(!errorReporter.errors.isEmpty)
        XCTAssertEqual(errorReporter.errors.last as? BitwardenTestError, BitwardenTestError.example)
    }

    /// `.receive()` with `.filePasswordConfirmationTextChanged()` updates the file password confirmation text.
    @MainActor
    func test_receive_filePasswordConfirmationTextChanged() {
        subject.receive(.filePasswordConfirmationTextChanged("file password"))

        XCTAssertEqual(subject.state.filePasswordConfirmationText, "file password")
    }

    /// `.receive()` with `.masterPasswordOrOtpTextChanged()` updates the master password/OTP text.
    @MainActor
    func test_receive_masterPasswordOrOtpTextChanged() {
        subject.receive(.masterPasswordOrOtpTextChanged("password"))

        XCTAssertEqual(subject.state.masterPasswordOrOtpText, "password")
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

    /// `.receive()` with `.toggleFilePasswordVisibility()` toggles the file password visibility.
    @MainActor
    func test_receive_toggleFilePasswordVisibility() {
        subject.receive(.toggleFilePasswordVisibility(true))
        XCTAssertTrue(subject.state.isFilePasswordVisible)

        subject.receive(.toggleFilePasswordVisibility(false))
        XCTAssertFalse(subject.state.isFilePasswordVisible)
    }

    /// `.receive()` with `.toggleMasterPasswordOrOtpVisibility()` toggles the master password/OTP visibility.
    @MainActor
    func test_receive_toggleMasterPasswordOrOtpVisibility() {
        subject.receive(.toggleMasterPasswordOrOtpVisibility(true))
        XCTAssertTrue(subject.state.isMasterPasswordOrOtpVisible)

        subject.receive(.toggleMasterPasswordOrOtpVisibility(false))
        XCTAssertFalse(subject.state.isMasterPasswordOrOtpVisible)
    }
} // swiftlint:disable:this file_length
