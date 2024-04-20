import XCTest

@testable import AuthenticatorShared

class AlertSettingsTests: AuthenticatorTestCase {
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

    /// `confirmApproveLoginRequests(action:)` constructs an `Alert` with the title,
    /// message, yes, and cancel buttons to confirm approving login requests
    func test_confirmApproveLoginRequests() {
        let subject = Alert.confirmApproveLoginRequests {}

        XCTAssertEqual(subject.title, Localizations.approveLoginRequests)
        XCTAssertEqual(subject.message, Localizations.useThisDeviceToApproveLoginRequestsMadeFromOtherDevices)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.alertActions.first?.title, Localizations.no)
        XCTAssertEqual(subject.alertActions.first?.style, .cancel)
        XCTAssertEqual(subject.alertActions.last?.title, Localizations.yes)
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

    /// `confirmExportItems(action:)` constructs an `Alert`
    ///  with the title, message, and Yes and Export items buttons.
    func test_confirmExportVault() {
        let subject = Alert.confirmExportItems {}

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.exportItemsConfirmationTitle)
        XCTAssertEqual(subject.message, Localizations.exportItemsWarning)
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

    /// `enterPINCode(completion:)` constructs an `Alert` with the correct title, message, Submit and Cancel buttons.
    func test_enterPINCodeAlert() {
        let subject = Alert.enterPINCode { _ in }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.enterPIN)
        XCTAssertEqual(subject.message, Localizations.setPINDescription)
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

    /// `unlockWithPINCodeAlert(action)` constructs an `Alert` with the correct title, message, Yes and No buttons.
    func test_unlockWithPINAlert() {
        let subject = Alert.unlockWithPINCodeAlert { _ in }

        XCTAssertEqual(subject.alertActions.count, 2)
        XCTAssertEqual(subject.preferredStyle, .alert)
        XCTAssertEqual(subject.title, Localizations.unlockWithPIN)
        XCTAssertEqual(subject.message, Localizations.pinRequireMasterPasswordRestart)
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
