import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

class AutofillHelperTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appExtensionDelegate: MockAppExtensionDelegate!
    var authRepository: MockAuthRepository!
    var coordinator: MockCoordinator<VaultRoute, AuthAction>!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var subject: AutofillHelper!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appExtensionDelegate = MockAppExtensionDelegate()
        authRepository = MockAuthRepository()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()
        vaultRepository = MockVaultRepository()

        subject = AutofillHelper(
            appExtensionDelegate: appExtensionDelegate,
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                authRepository: authRepository,
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                vaultRepository: vaultRepository
            )
        )
    }

    override func tearDown() {
        super.tearDown()

        appExtensionDelegate = nil
        authRepository = nil
        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        subject = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `handleCipherForAutofill(cipherListView:)` notifies the delegate of the username and
    /// password to autofill.
    @MainActor
    func test_handleCipherForAutofill() async {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com")
        ))

        let cipher = CipherListView.fixture(id: "1")
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequestUsername, "user@bitwarden.com")
        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequestPassword, "PASSWORD")
    }

    /// `handleCipherForAutofill(cipherListView:)` displays an alert for the user to copy the
    /// login's username or password if the extension is unable to autofill the credentials.
    @MainActor
    func test_handleCipherForAutofill_autofillNotSupported() async throws {
        appExtensionDelegate.canAutofill = false

        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com")
        ))

        let cipher = CipherListView.fixture(id: "1")
        var showToastValue: String?
        await subject.handleCipherForAutofill(cipherListView: cipher) { showToastValue = $0 }

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden")
        XCTAssertEqual(alert.preferredStyle, .actionSheet)
        XCTAssertEqual(alert.alertActions.count, 3)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.copyUsername)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.copyPassword)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)

        try await alert.tapAction(title: Localizations.copyUsername)
        XCTAssertEqual(pasteboardService.copiedString, "user@bitwarden.com")
        XCTAssertEqual(showToastValue, Localizations.valueHasBeenCopied(Localizations.username))

        try await alert.tapAction(title: Localizations.copyPassword)
        XCTAssertEqual(pasteboardService.copiedString, "PASSWORD")
        XCTAssertEqual(showToastValue, Localizations.valueHasBeenCopied(Localizations.password))
    }

    /// `handleCipherForAutofill(cipherListView:)` logs an error and shows an alert if one occurs.
    @MainActor
    func test_handleCipherForAutofill_error() async {
        authRepository.hasMasterPasswordResult = .failure(BitwardenTestError.example)
        vaultRepository.fetchCipherResult = .success(.fixture(reprompt: .password))

        let cipher = CipherListView.fixture(id: "1", reprompt: .password)
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
        XCTAssertEqual(coordinator.alertShown, [.defaultAlert(title: Localizations.anErrorHasOccurred)])
    }

    /// `handleCipherForAutofill(cipherListView:)` shows an alert if fetching the cipher results in an error.
    @MainActor
    func test_handleCipherForAutofill_fetchCipherError() async {
        let cipher = CipherListView.fixture()
        vaultRepository.fetchCipherResult = .failure(BitwardenTestError.example)
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
    }

    /// `handleCipherForAutofill(cipherListView:)` shows an alert if the cipher is missing an ID.
    @MainActor
    func test_handleCipherForAutofill_missingId() async {
        let cipher = CipherListView.fixture(id: nil)

        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        XCTAssertEqual(errorReporter.errors.count, 1)
        let nsError = errorReporter.errors.first as? NSError
        XCTAssertEqual(
            nsError?.userInfo["ErrorMessage"] as? String,
            "No cipher found on AutofillHelper handleCipherForAutofillAfterRepromptIfRequired."
        )
    }

    /// `handleCipherForAutofill(cipherListView:)` shows an alert if the cipher couldn't be fetched.
    @MainActor
    func test_handleCipherForAutofill_fetchNoCipher() async {
        let cipher = CipherListView.fixture(id: "1")
        vaultRepository.fetchCipherResult = .success(nil)

        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        XCTAssertEqual(coordinator.alertShown.last, .defaultAlert(title: Localizations.anErrorHasOccurred))
        guard errorReporter.errors.count == 1 else {
            XCTFail("No errors reported.")
            return
        }
        let nsError = errorReporter.errors[0] as NSError
        XCTAssertEqual(
            nsError.userInfo["ErrorMessage"] as? String,
            "No cipher found on AutofillHelper handleCipherForAutofillAfterRepromptIfRequired."
        )
    }

    /// `handleCipherForAutofill(cipherListView:)` shows an alert if the cipher is missing a password.
    @MainActor
    func test_handleCipherForAutofill_missingPassword() async throws {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: nil, username: "user@bitwarden.com"),
            name: "Bitwarden Login"
        ))

        let cipher = CipherListView.fixture(id: "1")
        var showToastValue: String?
        await subject.handleCipherForAutofill(cipherListView: cipher) { showToastValue = $0 }

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden Login")
        XCTAssertEqual(alert.preferredStyle, .actionSheet)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.copyUsername)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        try await alert.tapAction(title: Localizations.copyUsername)
        XCTAssertEqual(pasteboardService.copiedString, "user@bitwarden.com")
        XCTAssertEqual(showToastValue, Localizations.valueHasBeenCopied(Localizations.username))
    }

    /// `handleCipherForAutofill(cipherListView:)` shows an alert if the cipher is missing an username.
    @MainActor
    func test_handleCipherForAutofill_missingUsername() async throws {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: nil),
            name: "Bitwarden Login"
        ))

        let cipher = CipherListView.fixture(id: "1")
        var showToastValue: String?
        await subject.handleCipherForAutofill(cipherListView: cipher) { showToastValue = $0 }

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden Login")
        XCTAssertEqual(alert.preferredStyle, .actionSheet)
        XCTAssertEqual(alert.alertActions.count, 2)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.copyPassword)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.cancel)

        try await alert.tapAction(title: Localizations.copyPassword)
        XCTAssertEqual(pasteboardService.copiedString, "PASSWORD")
        XCTAssertEqual(showToastValue, Localizations.valueHasBeenCopied(Localizations.password))
    }

    /// `handleCipherForAutofill(cipherListView:)` shows an alert if the cipher is missing an
    /// username with options to copy the password and TOTP.
    @MainActor
    func test_handleCipherForAutofill_missingValueCopyTotp() async throws {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: nil, totp: "totp"),
            name: "Bitwarden Login"
        ))
        vaultRepository.refreshTOTPCodeResult = .success(
            LoginTOTPState(
                authKeyModel: TOTPKeyModel(authenticatorKey: .standardTotpKey),
                codeModel: TOTPCodeModel(code: "123321", codeGenerationDate: Date(), period: 30)
            )
        )

        let cipher = CipherListView.fixture(id: "1")
        var showToastValue: String?
        await subject.handleCipherForAutofill(cipherListView: cipher) { showToastValue = $0 }

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert.title, "Bitwarden Login")
        XCTAssertEqual(alert.preferredStyle, .actionSheet)
        XCTAssertEqual(alert.alertActions.count, 3)
        XCTAssertEqual(alert.alertActions[0].title, Localizations.copyPassword)
        XCTAssertEqual(alert.alertActions[1].title, Localizations.copyTotp)
        XCTAssertEqual(alert.alertActions[2].title, Localizations.cancel)

        try await alert.tapAction(title: Localizations.copyPassword)
        XCTAssertEqual(pasteboardService.copiedString, "PASSWORD")
        XCTAssertEqual(showToastValue, Localizations.valueHasBeenCopied(Localizations.password))

        try await alert.tapAction(title: Localizations.copyTotp)
        XCTAssertEqual(pasteboardService.copiedString, "123321")
        XCTAssertEqual(showToastValue, Localizations.valueHasBeenCopied(Localizations.verificationCodeTotp))
    }

    /// `handleCipherForAutofill(cipherListView:)` logs an error if generating the TOTP fails from
    /// the missing value alert.
    @MainActor
    func test_handleCipherForAutofill_missingValueCopyTotpError() async throws {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: nil, totp: "totp"),
            name: "Bitwarden Login"
        ))
        struct GenerateTotpError: Error, Equatable {}
        vaultRepository.refreshTOTPCodeResult = .failure(GenerateTotpError())

        let cipher = CipherListView.fixture(id: "1")
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        try await alert.tapAction(title: Localizations.copyTotp)
        XCTAssertEqual(errorReporter.errors.last as? GenerateTotpError, GenerateTotpError())
    }

    /// `handleCipherForAutofill(cipherListView:)` shows an alert if the cipher is missing an
    /// username and password.
    @MainActor
    func test_handleCipherForAutofill_missingUsernameAndPassword() async throws {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: nil, username: nil)
        ))

        let cipher = CipherListView.fixture(id: "1")
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .defaultAlert(title: Localizations.noUsernamePasswordConfigured))
    }

    /// `handleCipherForAutofill(cipherListView:)` displays an alert if the cipher requires a master
    /// password reprompt.
    @MainActor
    func test_handleCipherForAutofill_passwordReprompt() async throws {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com"),
            name: "Bitwarden Login",
            reprompt: .password
        ))

        let cipher = CipherListView.fixture(id: "1", reprompt: .password)
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        let alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .masterPasswordPrompt { _ in })
        var textField = try XCTUnwrap(alert.alertTextFields.first)
        textField = AlertTextField(id: "password", text: "password")
        let submitAction = try XCTUnwrap(alert.alertActions.first(where: { $0.title == Localizations.submit }))
        await submitAction.handler?(submitAction, [textField])

        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequestUsername, "user@bitwarden.com")
        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequestPassword, "PASSWORD")
    }

    /// `handleCipherForAutofill(cipherListView:)` displays an alert if the password reprompt
    /// validation fails.
    @MainActor
    func test_handleCipherForAutofill_passwordReprompt_invalidPassword() async throws {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com"),
            name: "Bitwarden Login",
            reprompt: .password
        ))
        authRepository.validatePasswordResult = .success(false)

        let cipher = CipherListView.fixture(id: "1", reprompt: .password)
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        var alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .masterPasswordPrompt { _ in })
        try await alert.tapAction(title: Localizations.submit)

        alert = try XCTUnwrap(coordinator.alertShown.last)
        XCTAssertEqual(alert, .defaultAlert(title: Localizations.invalidMasterPassword))
    }

    /// `handleCipherForAutofill(cipherListView:)` bypasses the master password reprompt if the
    /// user doesn't have a master password.
    @MainActor
    func test_handleCipherForAutofill_passwordReprompt_noMasterPassword() async throws {
        authRepository.hasMasterPasswordResult = .success(false)
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com"),
            name: "Bitwarden Login",
            reprompt: .password
        ))

        let cipher = CipherListView.fixture(id: "1")
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequestUsername, "user@bitwarden.com")
        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequestPassword, "PASSWORD")
    }

    /// `handleCipherForAutofill(cipherListView:)` logs an error if generating the TOTP fails.
    @MainActor
    func test_handleCipherForAutofill_generateTOTPError() async {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com", totp: "totp")
        ))
        struct GenerateTotpError: Error, Equatable {}
        vaultRepository.refreshTOTPCodeResult = .failure(GenerateTotpError())

        let cipher = CipherListView.fixture(id: "1")
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequestUsername, "user@bitwarden.com")
        XCTAssertEqual(appExtensionDelegate.didCompleteAutofillRequestPassword, "PASSWORD")
        XCTAssertEqual(errorReporter.errors.last as? GenerateTotpError, GenerateTotpError())
    }

    /// `handleCipherForAutofill(cipherListView:)` copies the TOTP code for the login.
    func test_handleCipherForAutofill_totpCopy() async {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com", totp: "totp")
        ))
        vaultRepository.getDisableAutoTotpCopyResult = .success(false)
        vaultRepository.refreshTOTPCodeResult = .success(
            LoginTOTPState(
                authKeyModel: TOTPKeyModel(authenticatorKey: .standardTotpKey),
                codeModel: TOTPCodeModel(code: "123321", codeGenerationDate: Date(), period: 30)
            )
        )

        let cipher = CipherListView.fixture(id: "1")
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        XCTAssertEqual(pasteboardService.copiedString, "123321")
    }

    /// `handleCipherForAutofill(cipherListView:)` copies the TOTP code for the login if the
    /// organization uses TOTP.
    func test_handleCipherForAutofill_totpCopyOrganizationUseTotp() async {
        vaultRepository.doesActiveAccountHavePremiumResult = false
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com", totp: "totp"),
            organizationUseTotp: true
        ))
        vaultRepository.getDisableAutoTotpCopyResult = .success(false)
        vaultRepository.refreshTOTPCodeResult = .success(
            LoginTOTPState(
                authKeyModel: TOTPKeyModel(authenticatorKey: .standardTotpKey),
                codeModel: TOTPCodeModel(code: "123321", codeGenerationDate: Date(), period: 30)
            )
        )

        let cipher = CipherListView.fixture(id: "1")
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        XCTAssertEqual(pasteboardService.copiedString, "123321")
    }

    /// `handleCipherForAutofill(cipherListView:)` doesn't copy the TOTP code for the login if the
    /// disable auto-copy TOTP setting is set.
    func test_handleCipherForAutofill_totpCopyDisabled() async {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com", totp: "totp")
        ))
        vaultRepository.getDisableAutoTotpCopyResult = .success(true)

        let cipher = CipherListView.fixture(id: "1")
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        XCTAssertNil(pasteboardService.copiedString)
    }

    /// `handleCipherForAutofill(cipherListView:)` doesn't copy the TOTP code if the user doesn't
    /// have premium.
    func test_handleCipherForAutofill_totpCopyWithoutPremium() async {
        vaultRepository.fetchCipherResult = .success(.fixture(
            login: .fixture(password: "PASSWORD", username: "user@bitwarden.com", totp: "totp")
        ))
        vaultRepository.doesActiveAccountHavePremiumResult = false

        let cipher = CipherListView.fixture(id: "1")
        await subject.handleCipherForAutofill(cipherListView: cipher) { _ in }

        XCTAssertNil(pasteboardService.copiedString)
    }
} // swiftlint:disable:this file_length
