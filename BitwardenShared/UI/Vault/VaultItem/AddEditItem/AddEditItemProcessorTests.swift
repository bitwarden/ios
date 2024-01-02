import Networking
import XCTest

@testable import BitwardenShared

// MARK: - AddItemProcessorTests

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
class AddEditItemProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var cameraService: MockCameraService!
    var coordinator: MockCoordinator<VaultItemRoute>!
    var errorReporter: MockErrorReporter!
    var pasteboardService: MockPasteboardService!
    var totpService: MockTOTPService!
    var subject: AddEditItemProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cameraService = MockCameraService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        pasteboardService = MockPasteboardService()
        totpService = MockTOTPService()
        vaultRepository = MockVaultRepository()
        subject = AddEditItemProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                cameraService: cameraService,
                errorReporter: errorReporter,
                pasteboardService: pasteboardService,
                totpService: totpService,
                vaultRepository: vaultRepository
            ),
            state: CipherItemState()
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        errorReporter = nil
        pasteboardService = nil
        subject = nil
        totpService = nil
        vaultRepository = nil
    }

    // MARK: Tests

    /// `didCancelGenerator()` navigates to the `.dismiss` route.
    func test_didCancelGenerator() {
        subject.didCancelGenerator()
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `didCompleteGenerator` with a password value updates the state with the new password value
    /// and navigates to the `.dismiss` route.
    func test_didCompleteGenerator_withPassword() {
        subject.state.loginState.username = "username123"
        subject.state.loginState.password = "password123"
        subject.didCompleteGenerator(for: .password, with: "password")
        XCTAssertEqual(coordinator.routes.last, .dismiss)
        XCTAssertEqual(subject.state.loginState.password, "password")
        XCTAssertEqual(subject.state.loginState.username, "username123")
    }

    /// `didCompleteGenerator` with a username value updates the state with the new username value
    /// and navigates to the `.dismiss` route.
    func test_didCompleteGenerator_withUsername() {
        subject.state.loginState.username = "username123"
        subject.state.loginState.password = "password123"
        subject.didCompleteGenerator(for: .username, with: "email@example.com")
        XCTAssertEqual(coordinator.routes.last, .dismiss)
        XCTAssertEqual(subject.state.loginState.username, "email@example.com")
        XCTAssertEqual(subject.state.loginState.password, "password123")
    }

    /// `didCompleteCapture` with a value updates the state with the new auth key value
    /// and navigates to the `.dismiss` route.
    func test_didCompleteCapture_failure() {
        subject.state.loginState.totpKey = nil
        totpService.getTOTPConfigResult = .failure(TOTPServiceError.invalidKeyFormat)
        let task = Task {
            subject.didCompleteCapture(with: "1234")
        }
        waitFor(!coordinator.routes.isEmpty && coordinator.routes.last != .dismiss)
        task.cancel()

        XCTAssertEqual(
            coordinator.routes.last,
            .alert(Alert(
                title: Localizations.authenticatorKeyReadError,
                message: nil,
                alertActions: [
                    AlertAction(title: Localizations.ok, style: .default),
                ]
            ))
        )
        XCTAssertNil(subject.state.loginState.authenticatorKey)
        XCTAssertNil(subject.state.toast)
    }

    /// `didCompleteCapture` with a value updates the state with the new auth key value
    /// and navigates to the `.dismiss` route.
    func test_didCompleteCapture_success() throws {
        subject.state.loginState.totpKey = nil
        let key = String.base32Key
        let keyConfig = try XCTUnwrap(TOTPCodeConfig(authenticatorKey: key))
        totpService.getTOTPConfigResult = .success(keyConfig)
        subject.didCompleteCapture(with: key)
        XCTAssertEqual(coordinator.routes.last, .dismiss)
        XCTAssertEqual(subject.state.loginState.authenticatorKey, .base32Key)
        XCTAssertEqual(subject.state.toast?.text, Localizations.authenticatorKeyAdded)
    }

    /// `perform(_:)` with `.checkPasswordPressed` checks the password.
    func test_perform_checkPasswordPressed() async {
        await subject.perform(.checkPasswordPressed)

        XCTAssertEqual(coordinator.routes.last, .alert(
            Alert(
                title: Localizations.passwordExposed(9_659_365),
                message: nil,
                alertActions: [
                    AlertAction(
                        title: Localizations.ok,
                        style: .default
                    ),
                ]
            )
        ))
    }

    /// Tapping the copy button on the auth key row dispatches the `.copyPassword` action.
    func test_perform_copyTotp() async throws {
        subject.state.loginState.totpKey = .init(authenticatorKey: "JBSWY3DPEHPK3PXP")

        await subject.perform(.copyTotpPressed)
        XCTAssertEqual(
            subject.state.loginState.authenticatorKey,
            pasteboardService.copiedString
        )
    }

    /// `perform(_:)` with `.fetchCipherOptions` fetches the ownership options for a cipher from the repository.
    func test_perform_fetchCipherOptions() async {
        vaultRepository.fetchCipherOwnershipOptions = [.personal(email: "user@bitwarden.com")]

        await subject.perform(.fetchCipherOptions)

        XCTAssertEqual(subject.state.ownershipOptions, [.personal(email: "user@bitwarden.com")])
    }

    /// `perform(_:)` with `.savePressed` displays an alert if name field is invalid.
    func test_perform_savePressed_invalidName() async throws {
        subject.state.name = "    "

        await subject.perform(.savePressed)

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: Localizations.validationFieldRequired(Localizations.name),
                alertActions: [AlertAction(title: Localizations.ok, style: .default)]
            )
        )
    }

    /// `perform(_:)` with `.savePressed` displays an alert if saving or updating fails.
    func test_perform_savePressed_genericErrorAlert() async throws {
        subject.state.name = "vault item"
        struct EncryptError: Error, Equatable {}
        vaultRepository.addCipherResult = .failure(EncryptError())

        await subject.perform(.savePressed)

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(title: Localizations.anErrorHasOccurred)
        )
    }

    /// `perform(_:)` with `.savePressed` displays an alert containing the message returned by the
    /// server if saving fails.
    func test_perform_savePressed_serverErrorAlert() async throws {
        let response = HTTPResponse.failure(statusCode: 400, body: APITestData.bitwardenErrorMessage.data)
        try vaultRepository.addCipherResult = .failure(
            ServerError.error(errorResponse: ErrorResponseModel(response: response))
        )
        subject.state.name = "vault item"
        await subject.perform(.savePressed)

        let alert = try XCTUnwrap(coordinator.alertShown.first)
        XCTAssertEqual(
            alert,
            Alert.defaultAlert(
                title: Localizations.anErrorHasOccurred,
                message: "You do not have permissions to edit this."
            )
        )
    }

    /// `perform(_:)` with `.savePressed` saves the item.
    func test_perform_savePressed_secureNote() async {
        subject.state.type = .secureNote
        subject.state.name = "secureNote"

        await subject.perform(.savePressed)

        try XCTAssertEqual(
            XCTUnwrap(vaultRepository.addCipherCiphers.first).type,
            .secureNote
        )

        try XCTAssertEqual(
            XCTUnwrap(vaultRepository.addCipherCiphers.first).name,
            "secureNote"
        )
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `perform(_:)` with `.savePressed` saves the item.
    func test_perform_savePressed() async {
        subject.state.name = "vault item"
        await subject.perform(.savePressed)

        try XCTAssertEqual(
            XCTUnwrap(vaultRepository.addCipherCiphers.first).creationDate.timeIntervalSince1970,
            Date().timeIntervalSince1970,
            accuracy: 1
        )
        try XCTAssertEqual(
            XCTUnwrap(vaultRepository.addCipherCiphers.first).revisionDate.timeIntervalSince1970,
            Date().timeIntervalSince1970,
            accuracy: 1
        )

        XCTAssertEqual(
            vaultRepository.addCipherCiphers,
            [
                (subject.state as? CipherItemState)?
                    .newCipherView(creationDate: vaultRepository.addCipherCiphers[0].creationDate),
            ]
        )
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `perform(_:)` with `.savePressed` forwards errors to the error reporter.
    func test_perform_savePressed_error() async {
        subject.state.name = "vault item"
        struct EncryptError: Error, Equatable {}
        vaultRepository.addCipherResult = .failure(EncryptError())
        await subject.perform(.savePressed)

        XCTAssertEqual(errorReporter.errors.first as? EncryptError, EncryptError())
    }

    /// `perform(_:)` with `.setupTotpPressed` with camera authorization authorized navigates to the
    /// `.setupTotpCamera` route.
    func test_perform_setupTotpPressed_cameraAuthorizationAuthorized() async {
        cameraService.cameraAuthorizationStatus = .authorized
        await subject.perform(.setupTotpPressed)

        XCTAssertEqual(coordinator.routes.last, .setupTotpCamera)
    }

    /// `perform(_:)` with `.setupTotpPressed` with camera authorization denied navigates to the
    /// `.setupTotpManual` route.
    func test_perform_setupTotpPressed_cameraAuthorizationDenied() async {
        cameraService.cameraAuthorizationStatus = .denied
        await subject.perform(.setupTotpPressed)

        XCTAssertEqual(coordinator.routes.last, .setupTotpManual)
    }

    /// `perform(_:)` with `.setupTotpPressed` with camera authorization restricted navigates to the
    /// `.setupTotpManual` route.
    func test_perform_setupTotpPressed_cameraAuthorizationRestricted() async {
        cameraService.cameraAuthorizationStatus = .restricted
        await subject.perform(.setupTotpPressed)

        XCTAssertEqual(coordinator.routes.last, .setupTotpManual)
    }

    /// `receive(_:)` with `.clearTOTPKey` clears the authenticator key.
    func test_receive_clearTOTPKey() {
        subject.state.loginState.totpKey = .init(authenticatorKey: .base32Key)
        subject.receive(.totpKeyChanged(nil))

        XCTAssertNil(subject.state.loginState.authenticatorKey)
    }

    /// `receive(_:)` with `.dismiss` navigates to the `.list` route.
    func test_receive_dismiss() {
        subject.receive(.dismissPressed)

        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `receive(_:)` with `.favoriteChanged` with `true` updates the state correctly.
    func test_receive_favoriteChanged_withTrue() {
        subject.state.isFavoriteOn = false

        subject.receive(.favoriteChanged(true))
        XCTAssertTrue(subject.state.isFavoriteOn)

        subject.receive(.favoriteChanged(true))
        XCTAssertTrue(subject.state.isFavoriteOn)
    }

    /// `receive(_:)` with `.favoriteChanged` with `false` updates the state correctly.
    func test_receive_favoriteChanged_withFalse() {
        subject.state.isFavoriteOn = true

        subject.receive(.favoriteChanged(false))
        XCTAssertFalse(subject.state.isFavoriteOn)

        subject.receive(.favoriteChanged(false))
        XCTAssertFalse(subject.state.isFavoriteOn)
    }

    /// `receive(_:)` with `.folderChanged` with a value updates the state correctly.
    func test_receive_folderChanged_withValue() {
        subject.state.folder = ""
        subject.receive(.folderChanged("📁"))

        XCTAssertEqual(subject.state.folder, "📁")
    }

    /// `receive(_:)` with `.folderChanged` without a value updates the state correctly.
    func test_receive_folderChanged_withoutValue() {
        subject.state.folder = "📁"
        subject.receive(.folderChanged(""))

        XCTAssertEqual(subject.state.folder, "")
    }

    /// `receive(_:)` with `.generatePasswordPressed` navigates to the `.generator` route.
    func test_receive_generatePasswordPressed() {
        subject.state.loginState.password = ""
        subject.receive(.generatePasswordPressed)

        XCTAssertEqual(coordinator.routes.last, .generator(.password))
    }

    /// `receive(_:)` with `.generateUsernamePressed` and with a password value in the state
    /// navigates to the `.alert` route.
    func test_receive_generatePasswordPressed_withUsernameValue() async throws {
        subject.state.loginState.password = "password"
        subject.receive(.generatePasswordPressed)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.passwordOverrideAlert)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions.count, 2)

        XCTAssertEqual(alert.alertActions[0].title, Localizations.no)
        XCTAssertEqual(alert.alertActions[0].style, .default)
        XCTAssertNil(alert.alertActions[0].handler)

        XCTAssertEqual(alert.alertActions[1].title, Localizations.yes)
        XCTAssertEqual(alert.alertActions[1].style, .default)
        XCTAssertNotNil(alert.alertActions[1].handler)
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(coordinator.routes.last, .generator(.password))
    }

    /// `receive(_:)` with `.generateUsernamePressed` and without a username value in the state
    /// navigates to the `.generator` route.
    func test_receive_generateUsernamePressed_withoutUsernameValue() {
        subject.state.loginState.username = ""
        subject.receive(.generateUsernamePressed)

        XCTAssertEqual(coordinator.routes.last, .generator(.username))
    }

    /// `receive(_:)` with `.generateUsernamePressed` and with a username value in the state
    /// navigates to the `.alert` route.
    func test_receive_generateUsernamePressed_withUsernameValue() async throws {
        subject.state.loginState.username = "username"
        subject.receive(.generateUsernamePressed)

        let alert = try coordinator.unwrapLastRouteAsAlert()
        XCTAssertEqual(alert.title, Localizations.areYouSureYouWantToOverwriteTheCurrentUsername)
        XCTAssertNil(alert.message)
        XCTAssertEqual(alert.alertActions.count, 2)

        XCTAssertEqual(alert.alertActions[0].title, Localizations.no)
        XCTAssertEqual(alert.alertActions[0].style, .default)
        XCTAssertNil(alert.alertActions[0].handler)

        XCTAssertEqual(alert.alertActions[1].title, Localizations.yes)
        XCTAssertEqual(alert.alertActions[1].style, .default)
        XCTAssertNotNil(alert.alertActions[1].handler)
        try await alert.tapAction(title: Localizations.yes)

        XCTAssertEqual(coordinator.routes.last, .generator(.username))
    }

    /// `receive(_:)` with `.generateUsernamePressed` passes the host of the first URI to the generator.
    func test_receive_generateUsernamePressed_withURI() async throws {
        subject.state.loginState.uris = [
            UriState(uri: "https://bitwarden.com"),
            UriState(uri: "https://example.com"),
        ]
        subject.receive(.generateUsernamePressed)
        XCTAssertEqual(coordinator.routes.last, .generator(.username, emailWebsite: "bitwarden.com"))

        subject.state.loginState.uris = [UriState(uri: "bitwarden.com")]
        subject.receive(.generateUsernamePressed)
        XCTAssertEqual(coordinator.routes.last, .generator(.username, emailWebsite: "bitwarden.com"))
    }

    /// `receive(_:)` with `.masterPasswordRePromptChanged` with `true` updates the state correctly.
    func test_receive_masterPasswordRePromptChanged_withTrue() {
        subject.state.isMasterPasswordRePromptOn = false

        subject.receive(.masterPasswordRePromptChanged(true))
        XCTAssertTrue(subject.state.isMasterPasswordRePromptOn)

        subject.receive(.masterPasswordRePromptChanged(true))
        XCTAssertTrue(subject.state.isMasterPasswordRePromptOn)
    }

    /// `receive(_:)` with `.masterPasswordRePromptChanged` with `false` updates the state correctly.
    func test_receive_masterPasswordRePromptChanged_withFalse() {
        subject.state.isMasterPasswordRePromptOn = true

        subject.receive(.masterPasswordRePromptChanged(false))
        XCTAssertFalse(subject.state.isMasterPasswordRePromptOn)

        subject.receive(.masterPasswordRePromptChanged(false))
        XCTAssertFalse(subject.state.isMasterPasswordRePromptOn)
    }

    /// `receive(_:)` with `.nameChanged` with a value updates the state correctly.
    func test_receive_nameChanged_withValue() {
        subject.state.name = ""
        subject.receive(.nameChanged("name"))

        XCTAssertEqual(subject.state.name, "name")
    }

    /// `receive(_:)` with `.nameChanged` without a value updates the state correctly.
    func test_receive_nameChanged_withoutValue() {
        subject.state.name = "name"
        subject.receive(.nameChanged(""))

        XCTAssertEqual(subject.state.name, "")
    }

    /// `receive(_:)` with `.newCustomFieldPressed` navigates to the `.alert` route.
    func test_receive_newCustomFieldPressed() {
        subject.receive(.newCustomFieldPressed)

        // TODO: BIT-368 Add alert assertion
        XCTAssertNil(coordinator.routes.last)
    }

    /// `receive(_:)` with `.newUriPressed` adds a new URI field to the state.
    func test_receive_newUriPressed() {
        subject.receive(.newUriPressed)

        // TODO: BIT-901 state assertion for added field
    }

    /// `receive(_:)` with `.notesChanged` with a value updates the state correctly.
    func test_receive_notesChanged_withValue() {
        subject.state.notes = ""
        subject.receive(.notesChanged("notes"))

        XCTAssertEqual(subject.state.notes, "notes")
    }

    /// `receive(_:)` with `.notesChanged` without a value updates the state correctly.
    func test_receive_notesChanged_withoutValue() {
        subject.state.notes = "notes"
        subject.receive(.notesChanged(""))

        XCTAssertEqual(subject.state.notes, "")
    }

    /// `receive(_:)` with `.ownerChanged` updates the state correctly.
    func test_receive_ownerChanged() {
        let personalOwner = CipherOwner.personal(email: "user@bitwarden.com")
        let organizationOwner = CipherOwner.organization(id: "1", name: "Organization")
        subject.state.ownershipOptions = [personalOwner, organizationOwner]

        XCTAssertEqual(subject.state.owner, personalOwner)

        subject.receive(.ownerChanged(organizationOwner))

        XCTAssertEqual(subject.state.owner, organizationOwner)
    }

    /// `receive(_:)` with `.passwordChanged` with a value updates the state correctly.
    func test_receive_passwordChanged_withValue() {
        subject.state.loginState.password = ""
        subject.receive(.passwordChanged("password"))

        XCTAssertEqual(subject.state.loginState.password, "password")
    }

    /// `receive(_:)` with `.passwordChanged` without a value updates the state correctly.
    func test_receive_passwordChanged_withoutValue() {
        subject.state.loginState.password = "password"
        subject.receive(.passwordChanged(""))

        XCTAssertEqual(subject.state.loginState.password, "")
    }

    /// `receive(_:)` with `.toastShown` without a value updates the state correctly.
    func test_receive_toastShown_withoutValue() {
        let toast = Toast(text: "123")
        subject.state.toast = toast
        subject.receive(.toastShown(nil))

        XCTAssertEqual(subject.state.toast, nil)
    }

    /// `receive(_:)` with `.toastShown` with a value updates the state correctly.
    func test_receive_toastShown_withValue() {
        let toast = Toast(text: "123")
        subject.receive(.toastShown(toast))

        XCTAssertEqual(subject.state.toast, toast)
    }

    /// `receive(_:)` with `.togglePasswordVisibilityChanged` with `true` updates the state correctly.
    func test_receive_togglePasswordVisibilityChanged_withTrue() {
        subject.state.loginState.isPasswordVisible = false

        subject.receive(.togglePasswordVisibilityChanged(true))
        XCTAssertTrue(subject.state.loginState.isPasswordVisible)

        subject.receive(.togglePasswordVisibilityChanged(true))
        XCTAssertTrue(subject.state.loginState.isPasswordVisible)
    }

    /// `receive(_:)` with `.togglePasswordVisibilityChanged` with `false` updates the state correctly.
    func test_receive_togglePasswordVisibilityChanged_withFalse() {
        subject.state.loginState.isPasswordVisible = true

        subject.receive(.togglePasswordVisibilityChanged(false))
        XCTAssertFalse(subject.state.loginState.isPasswordVisible)

        subject.receive(.togglePasswordVisibilityChanged(false))
        XCTAssertFalse(subject.state.loginState.isPasswordVisible)
    }

    /// `receive(_:)` with `.typeChanged` updates the state correctly.
    func test_receive_typeChanged() {
        subject.state.type = .login
        subject.receive(.typeChanged(.card))

        XCTAssertEqual(subject.state.type, .card)
    }

    /// `receive(_:)` with `.uriChanged` with a valid index updates the state correctly.
    func test_receive_uriChanged_withValidIndex() {
        subject.state.loginState.uris = [
            UriState(
                id: "id",
                matchType: .default,
                uri: ""
            ),
        ]
        subject.receive(.uriChanged("uri", index: 0))

        XCTAssertEqual(subject.state.loginState.uris[0].uri, "uri")
    }

    /// `receive(_:)` with `.uriChanged` without a valid index does not update the state.
    func test_receive_uriChanged_withoutValidIndex() {
        subject.state.loginState.uris = [
            UriState(
                id: "id",
                matchType: .default,
                uri: "uri"
            ),
        ]
        subject.receive(.uriChanged("new value", index: 5))

        XCTAssertEqual(subject.state.loginState.uris[0].uri, "uri")
    }

    /// `receive(_:)` with `.uriTypeChanged` with a valid id updates the state correctly.
    func test_receive_uriTypeChanged_withValidUriId() {
        subject.state.loginState.uris = [
            UriState(
                id: "id",
                matchType: .default,
                uri: "uri"
            ),
        ]
        subject.receive(.uriTypeChanged(.custom(.host), index: 0))

        XCTAssertEqual(subject.state.loginState.uris[0].matchType, .custom(.host))
    }

    /// `receive(_:)` with `.uriTypeChanged` without a valid id does not update the state.
    func test_receive_uriTypeChanged_withoutValidUriId() {
        subject.state.loginState.uris = [
            UriState(
                id: "id",
                matchType: .default,
                uri: "uri"
            ),
        ]
        subject.receive(.uriTypeChanged(.custom(.host), index: 5))

        XCTAssertEqual(subject.state.loginState.uris[0].matchType, .default)
    }

    /// `receive(_:)` with `.usernameChanged` without a value updates the state correctly.
    func test_receive_usernameChanged_withValue() {
        subject.state.loginState.username = ""
        subject.receive(.usernameChanged("username"))

        XCTAssertEqual(subject.state.loginState.username, "username")
    }

    /// `receive(_:)` with `.usernameChanged` without a value updates the state correctly.
    func test_receive_usernameChanged_withoutValue() {
        subject.state.loginState.username = "username"
        subject.receive(.usernameChanged(""))

        XCTAssertEqual(subject.state.loginState.username, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.titleChanged)` with a value updates the state correctly.
    func test_receive_identity_titleChange_withValidValue() {
        subject.state.identityState.title = .default
        subject.receive(.identityFieldChanged(.titleChanged(.custom(.mr))))
        XCTAssertEqual(subject.state.identityState.title, .custom(.mr))
    }

    /// `receive(_:)` with `.identityFieldChanged(.titleChanged)` without a value updates the state correctly.
    func test_receive_identity_titleChange_withOutValidValue() {
        subject.state.identityState.title = DefaultableType.custom(.mr)
        subject.receive(.identityFieldChanged(.titleChanged(DefaultableType.default)))
        XCTAssertEqual(subject.state.identityState.title, DefaultableType.default)
    }

    /// `receive(_:)` with `.identityFieldChanged(.firstNameChanged)` with a value updates the state correctly.
    func test_receive_identity_firstNameChange_withValidValue() {
        subject.state.identityState.firstName = ""
        subject.receive(.identityFieldChanged(.firstNameChanged("firstName")))

        XCTAssertEqual(subject.state.identityState.firstName, "firstName")
    }

    /// `receive(_:)` with `.identityFieldChanged(.firstNameChanged)` without a value updates the state correctly.
    func test_receive_identity_firstNameChange_withOutValidValue() {
        subject.state.identityState.firstName = "firstName"
        subject.receive(.identityFieldChanged(.firstNameChanged("")))

        XCTAssertEqual(subject.state.identityState.firstName, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.middleNameChanged)` with a value updates the state correctly.
    func test_receive_identity_middleNameChange_withValidValue() {
        subject.state.identityState.middleName = ""
        subject.receive(.identityFieldChanged(.middleNameChanged("middleName")))

        XCTAssertEqual(subject.state.identityState.middleName, "middleName")
    }

    /// `receive(_:)` with `.identityFieldChanged(.middleNameChanged)` without a value updates the state correctly.
    func test_receive_identity_middleNameChange_withOutValidValue() {
        subject.state.identityState.middleName = "middleName"
        subject.receive(.identityFieldChanged(.middleNameChanged("")))

        XCTAssertEqual(subject.state.identityState.middleName, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.lastNameChanged)` with a value updates the state correctly.
    func test_receive_identity_lastNameChange_withValidValue() {
        subject.state.identityState.lastName = ""
        subject.receive(.identityFieldChanged(.lastNameChanged("lastName")))

        XCTAssertEqual(subject.state.identityState.lastName, "lastName")
    }

    /// `receive(_:)` with `.identityFieldChanged(.lastNameChanged)` without a value updates the state correctly.
    func test_receive_identity_lastNameChange_withOutValidValue() {
        subject.state.identityState.lastName = "lastName"
        subject.receive(.identityFieldChanged(.lastNameChanged("")))

        XCTAssertEqual(subject.state.identityState.lastName, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.userNameChanged)` with a value updates the state correctly.
    func test_receive_identity_userNameChange_withValidValue() {
        subject.state.identityState.userName = ""
        subject.receive(.identityFieldChanged(.userNameChanged("userName")))

        XCTAssertEqual(subject.state.identityState.userName, "userName")
    }

    /// `receive(_:)` with `.identityFieldChanged(.userNameChanged)` without a value updates the state correctly.
    func test_receive_identity_userNameChange_withOutValidValue() {
        subject.state.identityState.userName = "userName"
        subject.receive(.identityFieldChanged(.userNameChanged("")))

        XCTAssertEqual(subject.state.identityState.userName, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.companyChanged)` with a value updates the state correctly.
    func test_receive_identity_companyChange_withValidValue() {
        subject.state.identityState.company = ""
        subject.receive(.identityFieldChanged(.companyChanged("company")))

        XCTAssertEqual(subject.state.identityState.company, "company")
    }

    /// `receive(_:)` with `.identityFieldChanged(.companyChanged)` without a value updates the state correctly.
    func test_receive_identity_companyChange_withOutValidValue() {
        subject.state.identityState.company = "company"
        subject.receive(.identityFieldChanged(.companyChanged("")))

        XCTAssertEqual(subject.state.identityState.company, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.passportNumberChanged)` with a value updates the state correctly.
    func test_receive_identity_passportNumberChange_withValidValue() {
        subject.state.identityState.passportNumber = ""
        subject.receive(.identityFieldChanged(.passportNumberChanged("passportNumber")))

        XCTAssertEqual(subject.state.identityState.passportNumber, "passportNumber")
    }

    /// `receive(_:)` with `.identityFieldChanged(.passportNumberChanged)` without a value updates the state correctly.
    func test_receive_identity_passportNumberChange_withOutValidValue() {
        subject.state.identityState.passportNumber = "passportNumber"
        subject.receive(.identityFieldChanged(.passportNumberChanged("")))

        XCTAssertEqual(subject.state.identityState.passportNumber, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.socialSecurityNumberChanged)`
    /// with a value updates the state correctly.
    func test_receive_identity_socialSecurityNumberChange_withValidValue() {
        subject.state.identityState.socialSecurityNumber = ""
        subject.receive(.identityFieldChanged(.socialSecurityNumberChanged("socialSecurityNumber")))

        XCTAssertEqual(subject.state.identityState.socialSecurityNumber, "socialSecurityNumber")
    }

    /// `receive(_:)` with `.identityFieldChanged(.passportNumberChanged)` without a value updates the state correctly.
    func test_receive_identity_socialSecurityNumberChange_withOutValidValue() {
        subject.state.identityState.passportNumber = "socialSecurityNumber"
        subject.receive(.identityFieldChanged(.socialSecurityNumberChanged("")))

        XCTAssertEqual(subject.state.identityState.socialSecurityNumber, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.licenseNumberChanged)` with a value updates the state correctly.
    func test_receive_identity_licenseNumberChange_withValidValue() {
        subject.state.identityState.licenseNumber = ""
        subject.receive(.identityFieldChanged(.licenseNumberChanged("licenseNumber")))

        XCTAssertEqual(subject.state.identityState.licenseNumber, "licenseNumber")
    }

    /// `receive(_:)` with `.identityFieldChanged(.licenseNumberChanged)` without a value updates the state correctly.
    func test_receive_identity_licenseNumberChange_withOutValidValue() {
        subject.state.identityState.licenseNumber = "licenseNumber"
        subject.receive(.identityFieldChanged(.licenseNumberChanged("")))

        XCTAssertEqual(subject.state.identityState.licenseNumber, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.emailChanged)` with a value updates the state correctly.
    func test_receive_identity_emailChange_withValidValue() {
        subject.state.identityState.email = ""
        subject.receive(.identityFieldChanged(.emailChanged("email")))

        XCTAssertEqual(subject.state.identityState.email, "email")
    }

    /// `receive(_:)` with `.identityFieldChanged(.emailChanged)` without a value updates the state correctly.
    func test_receive_identity_emailChange_withOutValidValue() {
        subject.state.identityState.email = "email"
        subject.receive(.identityFieldChanged(.emailChanged("")))

        XCTAssertEqual(subject.state.identityState.email, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.phoneNumberChanged)` with a value updates the state correctly.
    func test_receive_identity_phoneChange_withValidValue() {
        subject.state.identityState.phone = ""
        subject.receive(.identityFieldChanged(.phoneNumberChanged("phone")))

        XCTAssertEqual(subject.state.identityState.phone, "phone")
    }

    /// `receive(_:)` with `.identityFieldChanged(.phoneNumberChanged)` without a value updates the state correctly.
    func test_receive_identity_phoneChange_withOutValidValue() {
        subject.state.identityState.phone = "phone"
        subject.receive(.identityFieldChanged(.phoneNumberChanged("")))

        XCTAssertEqual(subject.state.identityState.phone, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.address1Changed)` with a value updates the state correctly.
    func test_receive_identity_address1Change_withValidValue() {
        subject.state.identityState.address1 = ""
        subject.receive(.identityFieldChanged(.address1Changed("address1")))

        XCTAssertEqual(subject.state.identityState.address1, "address1")
    }

    /// `receive(_:)` with `.identityFieldChanged(.address1Changed)` without a value updates the state correctly.
    func test_receive_identity_address1Change_withOutValidValue() {
        subject.state.identityState.address1 = "address1"
        subject.receive(.identityFieldChanged(.address1Changed("")))

        XCTAssertEqual(subject.state.identityState.address1, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.address2Changed)` with a value updates the state correctly.
    func test_receive_identity_address2Change_withValidValue() {
        subject.state.identityState.address2 = ""
        subject.receive(.identityFieldChanged(.address2Changed("address2")))

        XCTAssertEqual(subject.state.identityState.address2, "address2")
    }

    /// `receive(_:)` with `.identityFieldChanged(.address2Changed)` without a value updates the state correctly.
    func test_receive_identity_address2Change_withOutValidValue() {
        subject.state.identityState.address2 = "address2"
        subject.receive(.identityFieldChanged(.address2Changed("")))

        XCTAssertEqual(subject.state.identityState.address2, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.address3Changed)` with a value updates the state correctly.
    func test_receive_identity_address3Change_withValidValue() {
        subject.state.identityState.address3 = ""
        subject.receive(.identityFieldChanged(.address3Changed("address3")))

        XCTAssertEqual(subject.state.identityState.address3, "address3")
    }

    /// `receive(_:)` with `.identityFieldChanged(.address3Changed)` without a value updates the state correctly.
    func test_receive_identity_address3Change_withOutValidValue() {
        subject.state.identityState.address3 = "address3"
        subject.receive(.identityFieldChanged(.address3Changed("")))

        XCTAssertEqual(subject.state.identityState.address3, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.cityOrTownChanged)` with a value updates the state correctly.
    func test_receive_identity_cityOrTownChange_withValidValue() {
        subject.state.identityState.cityOrTown = ""
        subject.receive(.identityFieldChanged(.cityOrTownChanged("cityOrTown")))

        XCTAssertEqual(subject.state.identityState.cityOrTown, "cityOrTown")
    }

    /// `receive(_:)` with `.identityFieldChanged(.cityOrTownChanged)` without a value updates the state correctly.
    func test_receive_identity_cityOrTownChange_withOutValidValue() {
        subject.state.identityState.cityOrTown = "cityOrTown"
        subject.receive(.identityFieldChanged(.cityOrTownChanged("")))

        XCTAssertEqual(subject.state.identityState.cityOrTown, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.stateChanged)` with a value updates the state correctly.
    func test_receive_identity_stateChange_withValidValue() {
        subject.state.identityState.state = ""
        subject.receive(.identityFieldChanged(.stateChanged("state")))

        XCTAssertEqual(subject.state.identityState.state, "state")
    }

    /// `receive(_:)` with `.identityFieldChanged(.stateChanged)` without
    ///  a value updates the state correctly.
    func test_receive_identity_stateChange_withOutValidValue() {
        subject.state.identityState.state = "state"
        subject.receive(.identityFieldChanged(.stateChanged("")))

        XCTAssertEqual(subject.state.identityState.state, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.postalCodeChanged)` with a value updates the state correctly.
    func test_receive_identity_postalCodeChange_withValidValue() {
        subject.state.identityState.state = ""
        subject.receive(.identityFieldChanged(.postalCodeChanged("55408")))

        XCTAssertEqual(subject.state.identityState.postalCode, "55408")
    }

    /// `receive(_:)` with `.identityFieldChanged(.postalCodeChanged)` without
    ///  a value updates the state correctly.
    func test_receive_identity_postalCodeChange_withOutValidValue() {
        subject.state.identityState.postalCode = "55408"
        subject.receive(.identityFieldChanged(.postalCodeChanged("")))

        XCTAssertEqual(subject.state.identityState.postalCode, "")
    }

    /// `receive(_:)` with `.identityFieldChanged(.countryChanged)` with a value updates the state correctly.
    func test_receive_identity_countryChange_withValidValue() {
        subject.state.identityState.country = ""
        subject.receive(.identityFieldChanged(.countryChanged("country")))

        XCTAssertEqual(subject.state.identityState.country, "country")
    }

    /// `receive(_:)` with `.identityFieldChanged(.countryChanged)` without a value updates the state correctly.
    func test_receive_identity_countryChange_withOutValidValue() {
        subject.state.identityState.country = "country"
        subject.receive(.identityFieldChanged(.countryChanged("")))

        XCTAssertEqual(subject.state.identityState.country, "")
    }
}
