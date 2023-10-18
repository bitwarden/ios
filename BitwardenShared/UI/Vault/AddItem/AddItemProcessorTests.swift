import XCTest

@testable import BitwardenShared

// MARK: - AddItemProcessorTests

class AddItemProcessorTests: BitwardenTestCase {
    // MARK: Properties

    var coordinator: MockCoordinator<VaultRoute>!
    var subject: AddItemProcessor!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        coordinator = MockCoordinator()
        subject = AddItemProcessor(
            coordinator: coordinator.asAnyCoordinator(),
            state: AddItemState()
        )
    }

    override func tearDown() {
        super.tearDown()
        coordinator = nil
        subject = nil
    }

    // MARK: Tests

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

        XCTAssertEqual(coordinator.routes.last, .list)
    }

    /// `receive(_:)` with `.dismiss` navigates to the `.list` route.
    func test_receive_dismiss() {
        subject.receive(.dismissPressed)

        XCTAssertEqual(coordinator.routes.last, .list)
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
        subject.receive(.generatePasswordPressed)

        XCTAssertEqual(coordinator.routes.last, .generator)
    }

    /// `receive(_:)` with `.generateUsernamePressed` navigates to the `.generator` route.
    func test_receive_generateUsernamePressed() {
        subject.receive(.generateUsernamePressed)

        XCTAssertEqual(coordinator.routes.last, .generator)
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
        subject.state.password = ""
        subject.receive(.passwordChanged("password"))

        XCTAssertEqual(subject.state.password, "password")
    }

    /// `receive(_:)` with `.passwordChanged` without a value updates the state correctly.
    func test_receive_passwordChanged_withoutValue() {
        subject.state.password = "password"
        subject.receive(.passwordChanged(""))

        XCTAssertEqual(subject.state.password, "")
    }

    /// `receive(_:)` with `.setupTotpPressed` navigates to the `.setupTotpCamera` route.
    func test_receive_setupTotpPressed() {
        subject.receive(.setupTotpPressed)

        XCTAssertEqual(coordinator.routes.last, .setupTotpCamera)
    }

    /// `receive(_:)` with `.toggleFolderVisibilityChanged` with `true` updates the state correctly.
    func test_receive_toggleFolderVisibilityChanged_withTrue() {
        subject.state.isFolderVisible = false

        subject.receive(.toggleFolderVisibilityChanged(true))
        XCTAssertTrue(subject.state.isFolderVisible)

        subject.receive(.toggleFolderVisibilityChanged(true))
        XCTAssertTrue(subject.state.isFolderVisible)
    }

    /// `receive(_:)` with `.toggleFolderVisibilityChanged` with `false` updates the state correctly.
    func test_receive_toggleFolderVisibilityChanged_withFalse() {
        subject.state.isFolderVisible = true

        subject.receive(.toggleFolderVisibilityChanged(false))
        XCTAssertFalse(subject.state.isFolderVisible)

        subject.receive(.toggleFolderVisibilityChanged(false))
        XCTAssertFalse(subject.state.isFolderVisible)
    }

    /// `receive(_:)` with `.togglePasswordVisibilityChanged` with `true` updates the state correctly.
    func test_receive_togglePasswordVisibilityChanged_withTrue() {
        subject.state.isPasswordVisible = false

        subject.receive(.togglePasswordVisibilityChanged(true))
        XCTAssertTrue(subject.state.isPasswordVisible)

        subject.receive(.togglePasswordVisibilityChanged(true))
        XCTAssertTrue(subject.state.isPasswordVisible)
    }

    /// `receive(_:)` with `.togglePasswordVisibilityChanged` with `false` updates the state correctly.
    func test_receive_togglePasswordVisibilityChanged_withFalse() {
        subject.state.isPasswordVisible = true

        subject.receive(.togglePasswordVisibilityChanged(false))
        XCTAssertFalse(subject.state.isPasswordVisible)

        subject.receive(.togglePasswordVisibilityChanged(false))
        XCTAssertFalse(subject.state.isPasswordVisible)
    }

    /// `receive(_:)` with `.typeChanged` without a value updates the state correctly.
    func test_receive_typeChanged_withValue() {
        subject.state.type = ""
        subject.receive(.typeChanged("type"))

        XCTAssertEqual(subject.state.type, "type")
    }

    /// `receive(_:)` with `.typeChanged` without a value updates the state correctly.
    func test_receive_typeChanged_withoutValue() {
        subject.state.type = "type"
        subject.receive(.typeChanged(""))

        XCTAssertEqual(subject.state.type, "")
    }

    /// `receive(_:)` with `.uriChanged` without a value updates the state correctly.
    func test_receive_uriChanged_withValue() {
        subject.state.uri = ""
        subject.receive(.uriChanged("uri"))

        XCTAssertEqual(subject.state.uri, "uri")
    }

    /// `receive(_:)` with `.uriChanged` without a value updates the state correctly.
    func test_receive_uriChanged_withoutValue() {
        subject.state.uri = "uri"
        subject.receive(.uriChanged(""))

        XCTAssertEqual(subject.state.uri, "")
    }

    /// `receive(_:)` with `.uriSettingsPressed` navigates to the `.alert` route.
    func test_receive_uriSettingsPressed() {
        subject.receive(.uriSettingsPressed)

        // TODO: BIT-901 Add an `.alert` assertion
        XCTAssertNil(coordinator.routes.last)
    }

    /// `receive(_:)` with `.usernameChanged` without a value updates the state correctly.
    func test_receive_usernameChanged_withValue() {
        subject.state.username = ""
        subject.receive(.usernameChanged("username"))

        XCTAssertEqual(subject.state.username, "username")
    }

    /// `receive(_:)` with `.usernameChanged` without a value updates the state correctly.
    func test_receive_usernameChanged_withoutValue() {
        subject.state.username = "username"
        subject.receive(.usernameChanged(""))

        XCTAssertEqual(subject.state.username, "")
    }
}
