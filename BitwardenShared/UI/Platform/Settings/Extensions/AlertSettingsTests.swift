import BitwardenResources
import XCTest

@testable import BitwardenShared

class AlertSettingsTests: BitwardenTestCase {
    /// `appStoreAlert(action:)` constructs an `Alert` with the title,
    /// message, cancel, and continue buttons to confirm navigating to the app store.
    func test_appStoreAlert() {
        let subject = Alert.appStoreAlert {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.continueToAppStore)
        XCTAssertEqual(subject.message, Localizations.rateAppDescriptionLong)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.continue)
        XCTAssertEqual(subject.alertActions.last?.style, .default)
    }

    /// `confirmDeleteFolder(action:)` constructs an `Alert` with the title,
    /// message, yes, and cancel buttons to confirm deleting a folder.
    func test_confirmDeleteFolder() {
        let subject = Alert.confirmDeleteFolder {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.doYouReallyWantToDelete)
        XCTAssertNil(subject.message)
    }

    /// `confirmDeleteLog(action:)` constructs an `Alert` with the title,
    /// message, yes, and cancel buttons to confirm deleting a log.
    func test_confirmDeleteLog() async throws {
        var actionCalled = false
        let subject = Alert.confirmDeleteLog(isBulkDeletion: false) { actionCalled = true }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.doYouReallyWantToDeleteThisLog)
        XCTAssertNil(subject.message)

        try await subject.tapAction(title: Localizations.cancel)
        XCTAssertFalse(actionCalled)

        try await subject.tapAction(title: Localizations.yes)
        XCTAssertTrue(actionCalled)
    }

    /// `confirmDeleteLog(action:)` constructs an `Alert` with the title,
    /// message, yes, and cancel buttons to confirm deleting all logs.
    func test_confirmDeleteLog_bulkDeletion() async throws {
        var actionCalled = false
        let subject = Alert.confirmDeleteLog(isBulkDeletion: true) { actionCalled = true }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.doYouReallyWantToDeleteAllRecordedLogs)
        XCTAssertNil(subject.message)

        try await subject.tapAction(title: Localizations.cancel)
        XCTAssertFalse(actionCalled)

        try await subject.tapAction(title: Localizations.yes)
        XCTAssertTrue(actionCalled)
    }

    /// `confirmDenyingAllRequests(action:)` constructs an `Alert` with the title,
    /// message, yes, and cancel buttons to confirm denying all login requests
    func test_confirmDenyingAllRequests() {
        let subject = Alert.confirmDenyingAllRequests {}

        XCTAssertEqual(subject.title, Localizations.areYouSureYouWantToDeclineAllPendingLogInRequests)
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.no)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.yes)
        XCTAssertEqual(subject.alertActions.last?.style, .default)
    }

    /// `confirmExportVault(encrypted:action:)` constructs an `Alert` with the title, message, and Yes and Export vault
    /// buttons.
    func test_confirmExportVault() {
        var subject = Alert.confirmExportVault(encrypted: true) {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.exportVaultConfirmationTitle)
        XCTAssertEqual(
            subject.message,
            Localizations.exportVaultFilePwProtectInfo
        )

        subject = Alert.confirmExportVault(encrypted: false) {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.exportVaultConfirmationTitle)
        XCTAssertEqual(subject.message, Localizations.exportVaultWarning)
    }

    /// `displayFingerprintPhraseAlert(encrypted:action:)` constructs an `Alert`
    /// with the correct title, message, and Cancel and Learn More buttons.
    func test_displayFingerprintPhraseAlert() {
        let subject = Alert.displayFingerprintPhraseAlert(phrase: "phrase") {}

        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.fingerprintPhrase)
        XCTAssertEqual(subject.message, "\(Localizations.yourAccountsFingerprint):\n\nphrase")
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.close)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.learnMore)
        XCTAssertEqual(subject.alertActions.last?.style, .default)
    }

    /// `importItemsAlert(vaultUrl:action:)` constructs an `Alert`
    /// with the correct title, message, and Cancel and Continue buttons.
    func test_importItemsAlert() {
        let subject = Alert.importItemsAlert(importUrl: "https://www.example.com") {}

        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.continueToWebApp)
        XCTAssertEqual(subject.message, Localizations.youCanImportDataToYourVaultOnX("https://www.example.com"))
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.continue)
        XCTAssertEqual(subject.alertActions.last?.style, .default)
    }

    /// `languageChanged(to:)` constructs an `Alert` with the title and ok buttons.
    @MainActor
    func test_languageChanged() {
        let subject = Alert.languageChanged(to: "Thai") {}

        XCTAssertEqual(subject.title, Localizations.languageChangeXDescription("Thai"))
        XCTAssertNil(subject.message)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.ok)
        XCTAssertEqual(subject.alertActions.first?.style, .default)
    }

    /// `learnAboutOrganizationsAlert(encrypted:action:)` constructs an `Alert`
    /// with the correct title, message, and Cancel and Continue buttons.
    func test_learnAboutOrganizationsAlert() {
        let subject = Alert.learnAboutOrganizationsAlert {}

        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.learnOrg)
        XCTAssertEqual(subject.message, Localizations.learnAboutOrganizationsDescriptionLong)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.continue)
        XCTAssertEqual(subject.alertActions.last?.style, .default)
    }

    /// `logoutOnTimeoutAlert(action:)` constructs an `Alert` with the title, message, and Yes and Cancel buttons.
    func test_logoutOnTimeoutAlert() {
        let subject = Alert.logoutOnTimeoutAlert {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.warning)
        XCTAssertEqual(subject.message, Localizations.vaultTimeoutLogOutConfirmation)
    }

    /// `neverLockAlert(encrypted:action:)` constructs an `Alert`
    /// with the correct title, message, and Yes and Cancel buttons.
    func test_neverLockAlert() {
        let subject = Alert.neverLockAlert {}

        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.warning)
        XCTAssertEqual(subject.message, Localizations.neverLockWarning)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.yes)
        XCTAssertEqual(subject.alertActions.first?.style, .default)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions.last?.style, .cancel)
    }

    /// `privacyPolicyAlert(encrypted:action:)` constructs an `Alert`
    /// with the correct title, message, and Cancel and Continue buttons.
    func test_privacyPolicyAlert() {
        let subject = Alert.privacyPolicyAlert {}

        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.continueToPrivacyPolicy)
        XCTAssertEqual(subject.message, Localizations.privacyPolicyDescriptionLong)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.continue)
        XCTAssertEqual(subject.alertActions.last?.style, .default)
    }

    /// `timeoutExceedsPolicyLengthAlert()` constructs an `Alert` with the correct title, message, and Ok button.
    func test_timeoutExceedsPolicyLengthAlert() {
        let subject = Alert.timeoutExceedsPolicyLengthAlert()

        XCTAssertEqual(subject.title, Localizations.warning)
        XCTAssertEqual(subject.message, Localizations.vaultTimeoutToLarge)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.ok)
        XCTAssertEqual(subject.alertActions.count, 1)
        XCTAssertEqual(subject.alertActions.first?.style, .default)
    }

    /// `twoStepLoginAlert(encrypted:action:)` constructs an `Alert`
    /// with the correct title, message, and Cancel and Yes buttons.
    func test_twoStepLoginAlert() {
        let subject = Alert.twoStepLoginAlert {}

        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.continueToWebApp)
        XCTAssertEqual(subject.message, Localizations.twoStepLoginDescriptionLong)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.yes)
        XCTAssertEqual(subject.alertActions.last?.style, .default)
    }

    /// `unlockWithPINCodeAlert(action)` constructs an `Alert` with the correct title, message, Yes and No buttons
    /// when `biometricType` is `nil`.
    func test_unlockWithPINAlert() {
        let subject = Alert.unlockWithPINCodeAlert(biometricType: nil) { _ in }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.unlockWithPIN)
        XCTAssertEqual(subject.message, Localizations.pinRequireMasterPasswordRestart)
    }

    /// `unlockWithPINCodeAlert(action)` constructs an `Alert` with the correct title, message, Yes and No buttons
    /// when `biometricType` is `biometrics`.
    func test_unlockWithPINAlert_biometrics() {
        let subject = Alert.unlockWithPINCodeAlert(biometricType: .unknown) { _ in }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.unlockWithPIN)
        XCTAssertEqual(subject.message, Localizations.pinRequireUnknownBiometricsOrMasterPasswordRestart)
    }

    /// `unlockWithPINCodeAlert(action)` constructs an `Alert` with the correct title, message, Yes and No buttons
    /// when `biometricType` is `faceID`.
    func test_unlockWithPINAlert_faceID() {
        let subject = Alert.unlockWithPINCodeAlert(biometricType: .faceID) { _ in }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.unlockWithPIN)
        XCTAssertEqual(subject.message, Localizations.pinRequireBioOrMasterPasswordRestart(Localizations.faceID))
    }

    /// `unlockWithPINCodeAlert(action)` constructs an `Alert` with the correct title, message, Yes and No buttons
    /// when `biometricType` is `opticID`.
    func test_unlockWithPINAlert_opticID() {
        let subject = Alert.unlockWithPINCodeAlert(biometricType: .opticID) { _ in }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.unlockWithPIN)
        XCTAssertEqual(subject.message, Localizations.pinRequireBioOrMasterPasswordRestart(Localizations.opticID))
    }

    /// `unlockWithPINCodeAlert(action)` constructs an `Alert` with the correct title, message, Yes and No buttons
    /// when `biometricType` is `touchID`.
    func test_unlockWithPINAlert_touchID() {
        let subject = Alert.unlockWithPINCodeAlert(biometricType: .touchID) { _ in }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.unlockWithPIN)
        XCTAssertEqual(subject.message, Localizations.pinRequireBioOrMasterPasswordRestart(Localizations.touchID))
    }

    /// `verificationCodePrompt(completion:)` constructs an `Alert` used to ask the user to entered
    /// the verification code that was sent to their email.
    ///
    func test_verificationCodePrompt() async throws {
        var enteredOtp: String?
        let subject = Alert.verificationCodePrompt { otp in
            enteredOtp = otp
        }

        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.verificationCode)
        XCTAssertEqual(subject.message, Localizations.enterTheVerificationCodeThatWasSentToYourEmail)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.submit)
        XCTAssertEqual(subject.alertActions.first?.style, .default)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions.last?.style, .cancel)

        var textField = try XCTUnwrap(subject.alertTextFields.first)
        XCTAssertEqual(textField.keyboardType, .numberPad)
        textField = AlertTextField(id: "otp", text: "otp")

        let action = try XCTUnwrap(subject.alertActions.first(where: { $0.title == Localizations.submit }))
        await action.handler?(action, [textField])

        XCTAssertEqual(enteredOtp, "otp")
    }

    /// `webVaultAlert(encrypted:action:)` constructs an `Alert`
    /// with the correct title, message, and Cancel and Continue buttons.
    func test_webVaultAlert() {
        let subject = Alert.webVaultAlert {}

        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.continueToWebApp)
        XCTAssertEqual(subject.message, Localizations.exploreMoreFeaturesOfYourBitwardenAccountOnTheWebApp)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.cancel)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.continue)
        XCTAssertEqual(subject.alertActions.last?.style, .default)
    }
}
