import XCTest

@testable import BitwardenShared

// MARK: - AddItemProcessorTests

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
class AddEditItemProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var cameraAuthorizationService: MockCameraAuthorizationService!
    var coordinator: MockCoordinator<VaultItemRoute>!
    var errorReporter: MockErrorReporter!
    var subject: AddEditItemProcessor!
    var vaultRepository: MockVaultRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        cameraAuthorizationService = MockCameraAuthorizationService()
        coordinator = MockCoordinator()
        errorReporter = MockErrorReporter()
        vaultRepository = MockVaultRepository()
        subject = AddEditItemProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            services: ServiceContainer.withMocks(
                cameraAuthorizationService: cameraAuthorizationService,
                errorReporter: errorReporter,
                vaultRepository: vaultRepository
            ),
            state: .init()
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        errorReporter = nil
        subject = nil
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

    /// `perform(_:)` with `.savePressed` saves the item.
    func test_perform_savePressed() async {
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
            [subject.state.newCipherView(creationDate: vaultRepository.addCipherCiphers[0].creationDate)]
        )
        XCTAssertEqual(coordinator.routes.last, .dismiss)
    }

    /// `perform(_:)` with `.savePressed` forwards errors to the error reporter.
    func test_perform_savePressed_error() async {
        struct EncryptError: Error, Equatable {}
        vaultRepository.addCipherResult = .failure(EncryptError())
        await subject.perform(.savePressed)

        XCTAssertEqual(errorReporter.errors.first as? EncryptError, EncryptError())
    }

    /// `perform(_:)` with `.setupTotpPressed` with camera authorization authorized navigates to the
    /// `.setupTotpCamera` route.
    func test_perform_setupTotpPressed_cameraAuthorizationAuthorized() async {
        cameraAuthorizationService.cameraAuthorizationStatus = .authorized
        await subject.perform(.setupTotpPressed)

        XCTAssertEqual(coordinator.routes.last, .setupTotpCamera)
    }

    /// `perform(_:)` with `.setupTotpPressed` with camera authorization denied navigates to the
    /// `.setupTotpManual` route.
    func test_perform_setupTotpPressed_cameraAuthorizationDenied() async {
        cameraAuthorizationService.cameraAuthorizationStatus = .denied
        await subject.perform(.setupTotpPressed)

        XCTAssertEqual(coordinator.routes.last, .setupTotpManual)
    }

    /// `perform(_:)` with `.setupTotpPressed` with camera authorization restricted navigates to the
    /// `.setupTotpManual` route.
    func test_perform_setupTotpPressed_cameraAuthorizationRestricted() async {
        cameraAuthorizationService.cameraAuthorizationStatus = .restricted
        await subject.perform(.setupTotpPressed)

        XCTAssertEqual(coordinator.routes.last, .setupTotpManual)
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
            CipherLoginUriModel(
                match: nil,
                uri: "https://bitwarden.com"
            ),
            CipherLoginUriModel(
                match: nil,
                uri: "https://livefront.com"
            ),
        ]
        subject.receive(.generateUsernamePressed)
        XCTAssertEqual(coordinator.routes.last, .generator(.username, emailWebsite: "bitwarden.com"))

        subject.state.loginState.uris = [
            CipherLoginUriModel(
                match: nil,
                uri: "bitwarden.com"
            ),
        ]
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

    /// `receive(_:)` with `.ownerChanged` with a value updates the state correctly.
    func test_receive_ownerChanged_withValue() {
        subject.state.owner = ""
        subject.receive(.ownerChanged("owner"))

        XCTAssertEqual(subject.state.owner, "owner")
    }

    /// `receive(_:)` with `.ownerChanged` without a value updates the state correctly.
    func test_receive_ownerChanged_withoutValue() {
        subject.state.owner = "owner"
        subject.receive(.ownerChanged(""))

        XCTAssertEqual(subject.state.owner, "")
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

    /// `receive(_:)` with `.uriChanged` without a value updates the state correctly.
    func test_receive_uriChanged_withValue() {
        subject.state.loginState.uris = [
            .init(match: nil, uri: ""),
        ]
        subject.receive(.uriChanged("uri", index: 0))

        XCTAssertEqual(
            subject.state.loginState.uris,
            [CipherLoginUriModel(match: nil, uri: "uri")]
        )
    }

    /// `receive(_:)` with `.uriChanged` without a value updates the state correctly.
    func test_receive_uriChanged_withoutValue() {
        subject.state.loginState.uris = [
            .init(match: nil, uri: "uri"),
        ]
        subject.receive(.uriChanged("", index: 0))

        XCTAssertEqual(
            subject.state.loginState.uris,
            [CipherLoginUriModel(match: nil, uri: "")]
        )
    }

    /// `receive(_:)` with `.uriSettingsPressed` navigates to the `.alert` route.
    func test_receive_uriSettingsPressed() {
        subject.receive(.uriSettingsPressed)

        // TODO: BIT-901 Add an `.alert` assertion
        XCTAssertNil(coordinator.routes.last)
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
}
