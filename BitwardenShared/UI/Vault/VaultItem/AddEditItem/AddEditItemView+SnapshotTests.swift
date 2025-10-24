// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SnapshotTesting
import SwiftUI
import XCTest

@testable import BitwardenShared

// MARK: - AddEditItemViewTests

class AddEditItemViewTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var processor: MockProcessor<AddEditItemState, AddEditItemAction, AddEditItemEffect>!
    var subject: AddEditItemView!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        processor = MockProcessor(
            state: CipherItemState(
                hasPremium: true,
            ),
        )
        processor.state.ownershipOptions = [.personal(email: "user@bitwarden.com")]
        let store = Store(processor: processor)
        subject = AddEditItemView(store: store)
    }

    override func tearDown() {
        super.tearDown()
        processor = nil
        subject = nil
    }

    // MARK: Snapshots

    @MainActor
    func disabletest_snapshot_add_empty() {
        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    /// Tests the snapshot with the add state with the learn new login action card.
    @MainActor
    func disabletest_snapshot_learnNewLoginActionCard() throws {
        processor.state = CipherItemState(
            hasPremium: false,
        )
        processor.state.isLearnNewLoginActionCardEligible = true
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark],
        )
    }

    /// Tests the add state with identity item empty.
    @MainActor
    func disabletest_snapshot_add_identity_full_fieldsEmpty() {
        processor.state.type = .identity
        processor.state.name = ""
        processor.state.identityState = .init()
        processor.state.isAdditionalOptionsExpanded = true
        processor.state.isFavoriteOn = false
        processor.state.isMasterPasswordRePromptOn = false
        processor.state.notes = ""
        processor.state.folderId = nil

        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait2)
    }

    /// Tests the add state with identity item filled.
    @MainActor
    func disabletest_snapshot_add_identity_full_fieldsFilled() {
        processor.state.type = .identity
        processor.state.name = "my identity"
        processor.state.identityState = .fixture(
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
            country: "country",
        )
        processor.state.isAdditionalOptionsExpanded = true
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "A long segment of notes that proves that the multiline feature is working."
        processor.state.folderId = "1"
        processor.state.folders = [.custom(.fixture(id: "1", name: "Folder"))]

        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait2)
    }

    /// Tests the add state with identity item filled with large text.
    @MainActor
    func disabletest_snapshot_add_identity_full_fieldsFilled_largeText() {
        processor.state.type = .identity
        processor.state.name = "my identity"
        processor.state.identityState = .fixture(
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
            country: "country",
        )
        processor.state.isAdditionalOptionsExpanded = true
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folderId = "1"
        processor.state.folders = [.custom(.fixture(id: "1", name: "Folder"))]

        assertSnapshot(of: subject.navStackWrapped, as: .tallPortraitAX5(heightMultiple: 7))
    }

    /// Tests the add state with the password field not visible.
    @MainActor
    func disabletest_snapshot_add_login_full_fieldsNotVisible() {
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.loginState = .fixture(
            password: "password1!",
            uris: [
                .init(uri: URL.example.absoluteString),
            ],
            username: "username",
        )
        processor.state.isAdditionalOptionsExpanded = true
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.loginState.uris = [
            UriState(id: "id", matchType: .default, uri: URL.example.absoluteString),
        ]
        processor.state.notes = "Notes"
        processor.state.folderId = "1"
        processor.state.folders = [.custom(.fixture(id: "1", name: "Folder"))]

        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    /// Tests the add state with all fields.
    @MainActor
    func disabletest_snapshot_add_login_full_fieldsVisible() {
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.loginState.username = "username"
        processor.state.loginState.password = "password1!"
        processor.state.isAdditionalOptionsExpanded = true
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.loginState.uris = [
            UriState(id: "id", matchType: .default, uri: URL.example.absoluteString),
        ]
        processor.state.notes = "Notes"
        processor.state.folderId = "1"
        processor.state.folders = [.custom(.fixture(id: "1", name: "Folder"))]

        processor.state.loginState.isPasswordVisible = true

        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_add_login_collections() {
        processor.state.allUserCollections = [
            .fixture(id: "1", name: "Design", organizationId: "1"),
            .fixture(id: "2", name: "Engineering", organizationId: "1"),
        ]
        processor.state.ownershipOptions.append(.organization(id: "1", name: "Organization"))
        processor.state.owner = .organization(id: "1", name: "Organization")
        processor.state.collectionIds = ["2"]

        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_add_login_collectionsNone() {
        processor.state.ownershipOptions.append(.organization(id: "1", name: "Organization"))
        processor.state.owner = .organization(id: "1", name: "Organization")

        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_edit_full_fieldsNotVisible() {
        processor.state = CipherItemState(
            existing: CipherView.loginFixture(),
            hasPremium: true,
        )!
        processor.state.loginState = .fixture(
            fido2Credentials: [.fixture()],
            isPasswordVisible: false,
            password: "password1!",
            uris: [
                .init(uri: URL.example.absoluteString),
            ],
            username: "username",
        )
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.isAdditionalOptionsExpanded = true
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folderId = "1"
        processor.state.folders = [.custom(.fixture(id: "1", name: "Folder"))]
        processor.state.ownershipOptions = [.personal(email: "user@bitwarden.com")]

        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_edit_full_readOnly() {
        processor.state = CipherItemState(
            existing: CipherView.loginFixture(edit: false),
            hasPremium: true,
        )!
        processor.state.loginState = .fixture(
            fido2Credentials: [.fixture()],
            isPasswordVisible: false,
            password: "password1!",
            uris: [
                .init(uri: URL.example.absoluteString),
            ],
            username: "username",
        )
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.isAdditionalOptionsExpanded = true
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folderId = "1"
        processor.state.folders = [.custom(.fixture(id: "1", name: "Folder"))]
        processor.state.ownershipOptions = [.personal(email: "user@bitwarden.com")]

        assertSnapshots(
            of: subject.navStackWrapped,
            as: [
                .tallPortrait,
                .portraitDark(heightMultiple: 2),
            ],
        )
    }

    @MainActor
    func disabletest_snapshot_add_personalOwnershipPolicy() {
        processor.state.ownershipOptions.append(.organization(id: "1", name: "Organization"))
        processor.state.owner = .organization(id: "1", name: "Organization")
        processor.state.isPersonalOwnershipDisabled = true
        processor.state.allUserCollections = [
            .fixture(id: "1", name: "Default collection", organizationId: "1"),
        ]
        assertSnapshot(of: subject.navStackWrapped, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_add_secureNote_full_fieldsVisible() {
        processor.state.type = .secureNote
        processor.state.name = "Secure Note Name"
        processor.state.isAdditionalOptionsExpanded = true
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folderId = "1"
        processor.state.folders = [.custom(.fixture(id: "1", name: "Folder"))]

        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_edit_full_disabledViewPassword() {
        processor.state = CipherItemState(
            existing: CipherView.loginFixture(),
            hasPremium: true,
        )!
        processor.state.loginState = .fixture(
            canViewPassword: false,
            fido2Credentials: [.fixture()],
            isPasswordVisible: false,
            password: "password1!",
            uris: [
                .init(uri: URL.example.absoluteString),
            ],
            username: "username",
        )
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.isAdditionalOptionsExpanded = true
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folderId = "1"
        processor.state.folders = [.custom(.fixture(id: "1", name: "Folder"))]
        processor.state.ownershipOptions = [.personal(email: "user@bitwarden.com")]

        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_edit_full_fieldsNotVisible_largeText() {
        processor.state = CipherItemState(
            existing: CipherView.loginFixture(),
            hasPremium: true,
        )!
        processor.state.loginState = .fixture(
            fido2Credentials: [.fixture()],
            isPasswordVisible: false,
            password: "password1!",
            uris: [
                .init(uri: URL.example.absoluteString),
            ],
            username: "username",
        )
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.isAdditionalOptionsExpanded = true
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folderId = "1"
        processor.state.folders = [.custom(.fixture(id: "1", name: "Folder"))]
        processor.state.ownershipOptions = [.personal(email: "user@bitwarden.com")]

        assertSnapshot(of: subject.navStackWrapped, as: .tallPortraitAX5())
    }

    @MainActor
    func disabletest_snapshot_edit_full_fieldsVisible() {
        processor.state = CipherItemState(
            existing: CipherView.loginFixture(),
            hasPremium: true,
        )!
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.loginState = .fixture(
            fido2Credentials: [.fixture()],
            isPasswordVisible: true,
            password: "password1!",
            uris: [
                .init(uri: URL.example.absoluteString),
            ],
            username: "username",
        )
        processor.state.isAdditionalOptionsExpanded = true
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folderId = "1"
        processor.state.folders = [.custom(.fixture(id: "1", name: "Folder"))]
        processor.state.ownershipOptions = [.personal(email: "user@bitwarden.com")]

        assertSnapshot(of: subject.navStackWrapped, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_edit_full_fieldsVisible_largeText() {
        processor.state = CipherItemState(
            existing: CipherView.loginFixture(),
            hasPremium: true,
        )!
        processor.state.loginState = .fixture(
            fido2Credentials: [.fixture()],
            isPasswordVisible: true,
            password: "password1!",
            uris: [
                .init(uri: URL.example.absoluteString),
            ],
            username: "username",
        )
        processor.state.type = .login
        processor.state.name = "Name"
        processor.state.isAdditionalOptionsExpanded = true
        processor.state.isFavoriteOn = true
        processor.state.isMasterPasswordRePromptOn = true
        processor.state.notes = "Notes"
        processor.state.folderId = "1"
        processor.state.folders = [.custom(.fixture(id: "1", name: "Folder"))]
        processor.state.ownershipOptions = [.personal(email: "user@bitwarden.com")]

        assertSnapshot(of: subject.navStackWrapped, as: .tallPortraitAX5())
    }

    /// Test a snapshot of the AddEditView previews.
    func disabletest_snapshot_previews_addEditItemView() {
        for preview in AddEditItemView_Previews._allPreviews {
            assertSnapshots(
                of: preview.content,
                as: [
                    .tallPortrait,
                    .tallPortraitAX5(heightMultiple: 5),
                    .defaultPortraitDark,
                ],
            )
        }
    }

    /// Snapshots the previews for SSH key type.
    @MainActor
    func disabletest_snapshot_sshKey() {
        processor.state = sshKeyCipherItemState(
            canViewPrivateKey: true,
            isPrivateKeyVisible: false,
        )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Snapshots the previews for SSH key type when private key is visible.
    @MainActor
    func disabletest_snapshot_sshKeyPrivateKeyVisible() {
        processor.state = sshKeyCipherItemState(
            canViewPrivateKey: true,
            isPrivateKeyVisible: true,
        )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Snapshots the previews for SSH key type when `canViewPrivateKey` is `false`.
    @MainActor
    func disabletest_snapshot_sshKeyCantViewPrivateKey() {
        processor.state = sshKeyCipherItemState(
            canViewPrivateKey: false,
            isPrivateKeyVisible: false,
        )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    // MARK: Private

    /// Creates a `CipherItemState` for an SSH key item.
    /// - Parameters:
    ///   - canViewPrivateKey: Whether the private key can be viewed.
    ///   - isPrivateKeyVisible: Whether the private key is visible.
    /// - Returns: The `CipherItemState` for SSH key item.
    private func sshKeyCipherItemState(canViewPrivateKey: Bool, isPrivateKeyVisible: Bool) -> CipherItemState {
        var state = CipherItemState(
            existing: .fixture(
                id: "fake-id",
            ),
            hasPremium: true,
        )!
        state.name = "Example"
        state.type = .sshKey
        state.sshKeyState = SSHKeyItemState(
            canViewPrivateKey: canViewPrivateKey,
            isPrivateKeyVisible: isPrivateKeyVisible,
            privateKey: "ajsdfopij1ZXCVZXC12312QW",
            publicKey: "ssh-ed25519 AAAAA/asdjfoiwejrpo23323j23ASdfas",
            keyFingerprint: "SHA-256:2qwer233ADJOIq1adfweqe21321qw",
        )
        return state
    }
} // swiftlint:disable:this file_length
