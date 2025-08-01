import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SnapshotTesting
import SwiftUI
import ViewInspector
import XCTest

// swiftlint:disable file_length

@testable import BitwardenShared

// MARK: - ViewItemViewTests

class ViewItemViewTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var mockPresentTime = Date(year: 2023, month: 12, day: 31, minute: 0, second: 41)
    var timeProvider: TimeProvider!
    var processor: MockProcessor<ViewItemState, ViewItemAction, ViewItemEffect>!
    var subject: ViewItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        let state = ViewItemState()
        processor = MockProcessor(state: state)
        let store = Store(processor: processor)
        timeProvider = MockTimeProvider(.mockTime(mockPresentTime))
        subject = ViewItemView(store: store, timeProvider: timeProvider)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// Tapping the check password button dispatches the `.checkPasswordPressed` action.
    @MainActor
    func test_checkPasswordButton_tap() async throws {
        let loginState = CipherItemState(
            existing: .loginFixture(
                login: .fixture(
                    password: "password"
                ),
                name: "Name",
                revisionDate: Date()
            ),
            hasPremium: true
        )!
        processor.state.loadingState = .data(loginState)
        let button = try subject.inspect().find(asyncButtonWithAccessibilityLabel: Localizations.checkPassword)
        try await button.tap()
        XCTAssertEqual(processor.effects.last, .checkPasswordPressed)
    }

    /// Tapping the copy username button dispatches the `.copyPressed` action with the username.
    @MainActor
    func test_copyUsernameButton_tap() throws {
        let loginState = CipherItemState(
            existing: .loginFixture(
                login: .fixture(
                    username: "username"
                ),
                name: "Name",
                revisionDate: Date()
            ),
            hasPremium: true
        )!
        processor.state.loadingState = .data(loginState)
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copy)
        try button.tap()
        XCTAssertTrue(processor.dispatchedActions.contains(.copyPressed(value: "username", field: .username)))
    }

    /// Tapping the copy password button dispatches the `.copyPressed` action along with the
    /// password.
    @MainActor
    func test_copyPasswordButton_tap() throws {
        let loginState = CipherItemState(
            existing: .loginFixture(
                login: .fixture(password: "password"),
                revisionDate: Date()
            ),
            hasPremium: true
        )!
        processor.state.loadingState = .data(loginState)
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copy)
        try button.tap()
        XCTAssertTrue(processor.dispatchedActions.contains(.copyPressed(value: "password", field: .password)))
    }

    /// Tapping the copy uri button dispatches the `.copyPressed` action along with the uri.
    @MainActor
    func test_copyUriButton_tap() throws {
        let loginState = CipherItemState(
            existing: .loginFixture(
                login: .fixture(
                    uris: [
                        .fixture(uri: "www.example.com", match: nil),
                    ]
                ),
                name: "Name",
                revisionDate: Date()
            ),
            hasPremium: true
        )!
        processor.state.loadingState = .data(loginState)
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copy)
        try button.tap()
        XCTAssertTrue(processor.dispatchedActions.contains(.copyPressed(value: "www.example.com", field: .uri)))
    }

    /// Tapping the copy notes button dispatches the `.copyPressed` action along with the notes.
    @MainActor
    func test_copyNotesButton_tap() throws {
        let loginState = CipherItemState(
            existing: .loginFixture(
                name: "Name",
                notes: "Notes",
                revisionDate: Date()
            ),
            hasPremium: true
        )!
        processor.state.loadingState = .data(loginState)
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.copy)
        try button.tap()
        XCTAssertTrue(processor.dispatchedActions.contains(.copyPressed(value: "Notes", field: CopyableField.notes)))
    }

    /// Tapping the dismiss button dispatches the `.dismissPressed` action.
    @MainActor
    func test_dismissButton_tap() throws {
        let button = try subject.inspect().find(button: Localizations.close)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .dismissPressed)
    }

    /// Tapping the download attachment button dispatches the `.downloadAttachment(_)` action.
    @MainActor
    func test_downloadAttachmentButton_tap() throws {
        let state = try XCTUnwrap(CipherItemState(
            existing: .fixture(attachments: [.fixture(id: "2")]),
            hasPremium: true
        ))
        processor.state.loadingState = .data(state)
        let button = try subject.inspect().find(buttonWithAccessibilityLabel: Localizations.download)
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .downloadAttachment(.fixture(id: "2")))
    }

    /// Tapping the floating action button dispatches the `.editPressed` action.`
    @MainActor
    func test_editItemFloatingActionButton() async throws {
        let fab = try subject.inspect().find(
            floatingActionButtonWithAccessibilityIdentifier: "EditItemFloatingActionButton"
        )
        try await fab.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .editPressed)
    }

    /// The edit item FAB is hidden if the item has been deleted.
    @MainActor
    func test_editItemFloatingActionButton_hidden_cipherDeleted() async throws {
        processor.state.loadingState = .data(CipherItemState(existing: .fixture(deletedDate: .now), hasPremium: true)!)
        let fab = try subject.inspect().find(
            floatingActionButtonWithAccessibilityIdentifier: "EditItemFloatingActionButton"
        )
        XCTAssertTrue(fab.isHidden())
    }

    /// Tapping the password history button dispatches the `passwordHistoryPressed` action.
    @MainActor
    func test_passwordHistoryButton_tap() throws {
        processor.state.loadingState = .data(loginState())
        let button = try subject.inspect().find(buttonWithId: "passwordHistoryButton")
        try button.tap()
        XCTAssertEqual(processor.dispatchedActions.last, .passwordHistoryPressed)
    }

    /// Tapping the copy name button dispatches the `.copyPressed` action with the name.
    @MainActor
    func test_copyNameButton_tap() throws {
        processor.state.loadingState = .data(identityState())
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "IdentityCopyNameButton"
        ).button()
        try button.tap()
        XCTAssertTrue(processor.dispatchedActions.contains(.copyPressed(
            value: "Dr First Middle Last",
            field: .identityName
        )))
    }

    /// Tapping the copy identity username button dispatches the `.copyPressed` action with the identity username.
    @MainActor
    func test_copyIdentityUsernameButton_tap() throws {
        processor.state.loadingState = .data(identityState())
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "IdentityCopyUsernameButton"
        ).button()
        try button.tap()
        XCTAssertTrue(processor.dispatchedActions.contains(.copyPressed(
            value: "userName",
            field: .username
        )))
    }

    /// Tapping the copy company button dispatches the `.copyPressed` action with the company.
    @MainActor
    func test_copyCompanyButton_tap() throws {
        processor.state.loadingState = .data(identityState())
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "IdentityCopyCompanyButton"
        ).button()
        try button.tap()
        XCTAssertTrue(processor.dispatchedActions.contains(.copyPressed(
            value: "Company name",
            field: .company
        )))
    }

    /// Tapping the copy ssn button dispatches the `.copyPressed` action with the social security number.
    @MainActor
    func test_copySsnButton_tap() throws {
        processor.state.loadingState = .data(identityState())
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "IdentityCopySsnButton"
        ).button()
        try button.tap()
        XCTAssertTrue(processor.dispatchedActions.contains(.copyPressed(
            value: "12-345-6789",
            field: .socialSecurityNumber
        )))
    }

    /// Tapping the copy passport number button dispatches the `.copyPressed` action with the passport number.
    @MainActor
    func test_copyPassportButton_tap() throws {
        processor.state.loadingState = .data(identityState())
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "IdentityCopyPassportNumberButton"
        ).button()
        try button.tap()
        XCTAssertTrue(processor.dispatchedActions.contains(.copyPressed(
            value: "passport #",
            field: .passportNumber
        )))
    }

    /// Tapping the copy license number button dispatches the `.copyPressed` action with the license number.
    @MainActor
    func test_copyLicenseNumberButton_tap() throws {
        processor.state.loadingState = .data(identityState())
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "IdentityCopyLicenseNumberButton"
        ).button()
        try button.tap()
        XCTAssertTrue(processor.dispatchedActions.contains(.copyPressed(
            value: "license #",
            field: .licenseNumber
        )))
    }

    /// Tapping the copy phone button dispatches the `.copyPressed` action with the phone.
    @MainActor
    func test_copyPhoneButton_tap() throws {
        processor.state.loadingState = .data(identityState())
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "IdentityCopyPhoneButton"
        ).button()
        try button.tap()
        XCTAssertTrue(processor.dispatchedActions.contains(.copyPressed(
            value: "(123) 456-7890",
            field: .phone
        )))
    }

    /// Tapping the copy email button dispatches the `.copyPressed` action with the email.
    @MainActor
    func test_copyEmailButton_tap() throws {
        processor.state.loadingState = .data(identityState())
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "IdentityCopyEmailButton"
        ).button()
        try button.tap()
        XCTAssertTrue(processor.dispatchedActions.contains(.copyPressed(
            value: "hello@email.com",
            field: .email
        )))
    }

    /// Tapping the copy fullAddress button dispatches the `.copyPressed` action with the full address.
    @MainActor
    func test_copyAddressButton_tap() throws {
        processor.state.loadingState = .data(identityState())
        let button = try subject.inspect().find(
            viewWithAccessibilityIdentifier: "IdentityCopyFullAddressButton"
        ).button()
        try button.tap()
        XCTAssertTrue(processor.dispatchedActions.contains(.copyPressed(
            value: "123 street\naddress2\naddress3\nCity, State, 1234\ncountry",
            field: .fullAddress
        )))
    }

    /// Tapping the toggle to display multiple collections dispatches the `.toggleDisplayMultipleCollections` effect.
    @MainActor
    func test_toggleDisplayMultipleCollectionsButton_tap() async throws {
        var cipherState = loginState(collectionIds: ["1", "2"])
        cipherState.allUserCollections = [
            .fixture(id: "1"),
            .fixture(id: "2"),
            .fixture(id: "3"),
        ]
        cipherState.isShowingMultipleCollections = true
        processor.state.loadingState = .data(cipherState)
        let button = try subject.inspect().find(
            asyncButton: Localizations.showLess
        )
        try await button.tap()
        XCTAssertTrue(processor.effects.contains(.toggleDisplayMultipleCollections))
    }

    // MARK: Snapshots

    @MainActor
    func test_snapshot_loading() {
        processor.state.loadingState = .loading(nil)
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func identityState() -> CipherItemState {
        var cipherState = CipherItemState(
            existing: .fixture(
                id: "1234",
                name: "identity example",
                type: .identity
            ),
            hasPremium: true
        )!
        cipherState.folderId = "1"
        cipherState.folders = [.custom(.fixture(id: "1", name: "Folder"))]
        cipherState.folderName = "Folder"
        cipherState.notes = "Notes"
        cipherState.updatedDate = Date(year: 2023, month: 11, day: 11, hour: 9, minute: 41)
        cipherState.identityState = .fixture(
            title: .custom(.dr),
            firstName: "First",
            lastName: "Last",
            middleName: "Middle",
            userName: "userName",
            company: "Company name",
            socialSecurityNumber: "12-345-6789",
            passportNumber: "passport #",
            licenseNumber: "license #",
            email: "hello@email.com",
            phone: "(123) 456-7890",
            address1: "123 street",
            address2: "address2",
            address3: "address3",
            cityOrTown: "City",
            state: "State",
            postalCode: "1234",
            country: "country"
        )
        return cipherState
    }

    func loginState( // swiftlint:disable:this function_body_length
        canViewPassword: Bool = true,
        collectionIds: [String] = ["1", "2"],
        isFavorite: Bool = false,
        isPasswordVisible: Bool = true,
        hasPremium: Bool = true,
        hasTotp: Bool = true
    ) -> CipherItemState {
        var cipherState = CipherItemState(
            existing: .fixture(
                collectionIds: collectionIds,
                favorite: isFavorite,
                id: "fake-id"
            ),
            hasPremium: hasPremium
        )!
        cipherState.accountHasPremium = hasPremium
        cipherState.allUserCollections = [
            .fixture(id: "1", name: "Collection 1"),
            .fixture(id: "2", name: "Collection 2"),
        ]
        cipherState.collectionIds = collectionIds
        cipherState.folderId = "1"
        cipherState.folders = [.custom(.fixture(id: "1", name: "Folder"))]
        cipherState.folderName = "Folder"
        cipherState.name = "Example"
        cipherState.notes = "Notes"
        cipherState.organizationName = "Organization"
        cipherState.updatedDate = Date(year: 2023, month: 11, day: 11, hour: 9, minute: 41)
        cipherState.loginState.canViewPassword = canViewPassword
        cipherState.loginState.fido2Credentials = [.fixture()]
        cipherState.loginState.isPasswordVisible = isPasswordVisible
        cipherState.loginState.password = "Password1234!"
        cipherState.loginState.passwordHistoryCount = 4
        cipherState.loginState.passwordUpdatedDate = Date(year: 2023, month: 11, day: 11, hour: 9, minute: 41)
        cipherState.loginState.username = "email@example.com"
        if hasTotp {
            cipherState.loginState.totpState = .init(
                authKeyModel: .init(authenticatorKey: .standardTotpKey),
                codeModel: .init(
                    code: "032823",
                    codeGenerationDate: Date(year: 2023, month: 12, day: 31, minute: 0, second: 33),
                    period: 30
                )
            )
        }
        cipherState.loginState.uris = [
            UriState(
                matchType: .custom(.startsWith),
                uri: "https://www.example.com"
            ),
            UriState(
                matchType: .custom(.exact),
                uri: "https://www.example.com/account/login"
            ),
        ]

        cipherState.customFieldsState.customFields = [
            CustomFieldState(
                linkedIdType: nil,
                name: "Text",
                type: .text,
                value: "Value"
            ),
            CustomFieldState(
                linkedIdType: nil,
                name: "Text empty",
                type: .text,
                value: nil
            ),
            CustomFieldState(
                isPasswordVisible: false,
                linkedIdType: nil,
                name: "Hidden Hidden",
                type: .hidden,
                value: "pa$$w0rd"
            ),
            CustomFieldState(
                isPasswordVisible: true,
                linkedIdType: nil,
                name: "Hidden Shown",
                type: .hidden,
                value: "pa$$w0rd"
            ),
            CustomFieldState(
                linkedIdType: nil,
                name: "Boolean True",
                type: .boolean,
                value: "true"
            ),
            CustomFieldState(
                linkedIdType: nil,
                name: "Boolean False",
                type: .boolean,
                value: "false"
            ),
            CustomFieldState(
                linkedIdType: .loginUsername,
                name: "Linked",
                type: .linked,
                value: nil
            ),
        ]
        return cipherState
    }

    @MainActor
    func test_snapshot_identity_withAllValues() {
        processor.state.loadingState = .data(identityState())
        assertSnapshot(of: subject, as: .portrait(heightMultiple: 1.5))
    }

    @MainActor
    func test_snapshot_identity_withAllValues_largeText() {
        processor.state.loadingState = .data(identityState())
        assertSnapshot(of: subject, as: .tallPortraitAX5(heightMultiple: 4))
    }

    @MainActor
    func test_snapshot_login_disabledViewPassword() {
        processor.state.loadingState = .data(
            loginState(
                canViewPassword: false,
                isPasswordVisible: false
            )
        )

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    @MainActor
    func test_snapshot_login_empty() {
        let loginState = CipherItemState(
            existing: .fixture(
                favorite: true,
                id: "fake-id"
            ),
            hasPremium: true
        )!
        processor.state.loadingState = .data(loginState)

        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func test_snapshot_login_withAllValues() {
        processor.state.loadingState = .data(loginState(isFavorite: true))
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    @MainActor
    func test_snapshot_login_withAllValues_noPremium() {
        let loginState = loginState(hasPremium: false)
        processor.state.loadingState = .data(loginState)
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    @MainActor
    func test_snapshot_login_withAllValues_noPremium_largeText() {
        let loginState = loginState(hasPremium: false)
        processor.state.loadingState = .data(loginState)
        assertSnapshot(of: subject, as: .tallPortraitAX5(heightMultiple: 5))
    }

    @MainActor
    func test_snapshot_login_withAllValues_largeText() {
        processor.state.loadingState = .data(loginState())
        assertSnapshot(of: subject, as: .tallPortraitAX5(heightMultiple: 5))
    }

    @MainActor
    func test_snapshot_login_withAllValues_exceptTotp_noPremium() {
        let loginState = loginState(hasPremium: false, hasTotp: false)
        processor.state.loadingState = .data(loginState)
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    @MainActor
    func test_snapshot_login_withAllValuesExceptOrganization() {
        var state = loginState(collectionIds: [])
        state.organizationId = nil
        state.organizationName = nil
        state.collectionIds = []
        state.allUserCollections = []
        processor.state.loadingState = .data(state)
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    @MainActor
    func test_snapshot_login_withAllValuesShowMore() {
        let state = loginState(isFavorite: true)
        processor.state.loadingState = .data(state)
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    /// Snapshots the previews for card types.
    @MainActor
    func test_snapshot_previews_card() {
        assertSnapshot(
            of: ViewItemView_Previews.cardPreview,
            as: .defaultPortrait
        )
    }

    /// Snapshots the previews for card types.
    @MainActor
    func test_snapshot_previews_card_dark() {
        assertSnapshot(
            of: ViewItemView_Previews.cardPreview,
            as: .defaultPortraitDark
        )
    }

    /// Snapshots the previews for card types.
    @MainActor
    func test_snapshot_previews_card_largeText() {
        assertSnapshot(
            of: ViewItemView_Previews.cardPreview,
            as: .tallPortraitAX5(heightMultiple: 3)
        )
    }

    /// Snapshots the previews for login types.
    @MainActor
    func test_snapshot_previews_login() {
        assertSnapshot(
            of: ViewItemView_Previews.loginPreview,
            as: .tallPortrait
        )
    }

    /// Snapshots the previews for login types.
    @MainActor
    func test_snapshot_previews_login_dark() {
        assertSnapshot(
            of: ViewItemView_Previews.loginPreview,
            as: .portraitDark(heightMultiple: 2)
        )
    }

    /// Snapshots the previews for login types.
    @MainActor
    func test_snapshot_previews_login_largeText() {
        assertSnapshot(
            of: ViewItemView_Previews.loginPreview,
            as: .tallPortraitAX5(heightMultiple: 4)
        )
    }

    /// Snapshots the previews for secure note types.
    @MainActor
    func test_snapshot_previews_secureNote() {
        assertSnapshot(
            of: ViewItemView_Previews.secureNotePreview,
            as: .defaultPortrait
        )
    }

    /// Snapshots the previews for login types.
    @MainActor
    func test_snapshot_previews_sshKey() {
        assertSnapshot(
            of: ViewItemView_Previews.sshKeyPreview,
            as: .tallPortrait
        )
    }

    /// Snapshots the previews for SSH key type.
    @MainActor
    func test_snapshot_sshKey() {
        processor.state.loadingState =
            .data(
                sshKeyCipherItemState(
                    canViewPrivateKey: true,
                    isPrivateKeyVisible: false
                )
            )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// Snapshots the previews for SSH key type when private key is visible.
    @MainActor
    func test_snapshot_sshKeyPrivateKeyVisible() {
        processor.state.loadingState =
            .data(
                sshKeyCipherItemState(
                    canViewPrivateKey: true,
                    isPrivateKeyVisible: true
                )
            )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    /// Snapshots the previews for SSH key type when `canViewPrivateKey` is `false`.
    @MainActor
    func test_snapshot_sshKeyCantViewPrivateKey() {
        processor.state.loadingState =
            .data(
                sshKeyCipherItemState(
                    canViewPrivateKey: false,
                    isPrivateKeyVisible: false
                )
            )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5]
        )
    }

    // MARK: Private

    /// Creates a `CipherItemState` for an SSH key item.
    /// - Parameters:
    ///   - canViewPrivateKey: Whether the private key can be viewed.
    ///   - isPrivateKeyVisible: Whether the private key is visible
    /// - Returns: The `CipherItemState` for SSH key item.
    private func sshKeyCipherItemState(canViewPrivateKey: Bool, isPrivateKeyVisible: Bool) -> CipherItemState {
        var state = CipherItemState(
            existing: .fixture(
                id: "fake-id",
                type: .sshKey
            ),
            hasPremium: true
        )!
        state.name = "Example"
        state.type = .sshKey
        state.sshKeyState = SSHKeyItemState(
            canViewPrivateKey: canViewPrivateKey,
            isPrivateKeyVisible: isPrivateKeyVisible,
            privateKey: "ajsdfopij1ZXCVZXC12312QW",
            publicKey: "ssh-ed25519 AAAAA/asdjfoiwejrpo23323j23ASdfas",
            keyFingerprint: "SHA-256:2qwer233ADJOIq1adfweqe21321qw"
        )
        return state
    }
}
