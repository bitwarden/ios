// swiftlint:disable:this file_name
import BitwardenKit
import BitwardenKitMocks
import BitwardenResources
import BitwardenSdk
import SnapshotTesting
import SwiftUI
import XCTest

// swiftlint:disable file_length

@testable import BitwardenShared
@testable import BitwardenSharedMocks

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

    // MARK: Snapshots

    @MainActor
    func disabletest_snapshot_loading() {
        processor.state.loadingState = .loading(nil)
        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    func identityState() -> CipherItemState {
        var cipherState = CipherItemState(
            existing: .fixture(
                id: "1234",
                name: "identity example",
                type: .identity,
            ),
            hasPremium: true,
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
            country: "country",
        )
        return cipherState
    }

    func loginState( // swiftlint:disable:this function_body_length
        canViewPassword: Bool = true,
        collectionIds: [String] = ["1", "2"],
        isFavorite: Bool = false,
        isPasswordVisible: Bool = true,
        hasPremium: Bool = true,
        hasTotp: Bool = true,
    ) -> CipherItemState {
        var cipherState = CipherItemState(
            existing: .fixture(
                collectionIds: collectionIds,
                favorite: isFavorite,
                id: "fake-id",
            ),
            hasPremium: hasPremium,
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
                    period: 30,
                ),
            )
        }
        cipherState.loginState.uris = [
            UriState(
                matchType: .custom(.startsWith),
                uri: "https://www.example.com",
            ),
            UriState(
                matchType: .custom(.exact),
                uri: "https://www.example.com/account/login",
            ),
        ]

        cipherState.customFieldsState.customFields = [
            CustomFieldState(
                linkedIdType: nil,
                name: "Text",
                type: .text,
                value: "Value",
            ),
            CustomFieldState(
                linkedIdType: nil,
                name: "Text empty",
                type: .text,
                value: nil,
            ),
            CustomFieldState(
                isPasswordVisible: false,
                linkedIdType: nil,
                name: "Hidden Hidden",
                type: .hidden,
                value: "pa$$w0rd",
            ),
            CustomFieldState(
                isPasswordVisible: true,
                linkedIdType: nil,
                name: "Hidden Shown",
                type: .hidden,
                value: "pa$$w0rd",
            ),
            CustomFieldState(
                linkedIdType: nil,
                name: "Boolean True",
                type: .boolean,
                value: "true",
            ),
            CustomFieldState(
                linkedIdType: nil,
                name: "Boolean False",
                type: .boolean,
                value: "false",
            ),
            CustomFieldState(
                linkedIdType: .loginUsername,
                name: "Linked",
                type: .linked,
                value: nil,
            ),
        ]
        return cipherState
    }

    @MainActor
    func disabletest_snapshot_identity_withAllValues() {
        processor.state.loadingState = .data(identityState())
        assertSnapshot(of: subject, as: .portrait(heightMultiple: 1.5))
    }

    @MainActor
    func disabletest_snapshot_identity_withAllValues_largeText() {
        processor.state.loadingState = .data(identityState())
        assertSnapshot(of: subject, as: .tallPortraitAX5(heightMultiple: 4))
    }

    @MainActor
    func disabletest_snapshot_login_disabledViewPassword() {
        processor.state.loadingState = .data(
            loginState(
                canViewPassword: false,
                isPasswordVisible: false,
            ),
        )

        assertSnapshot(of: subject, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_login_empty() {
        let loginState = CipherItemState(
            existing: .fixture(
                favorite: true,
                id: "fake-id",
            ),
            hasPremium: true,
        )!
        processor.state.loadingState = .data(loginState)

        assertSnapshot(of: subject, as: .defaultPortrait)
    }

    @MainActor
    func disabletest_snapshot_login_withAllValues() {
        processor.state.loadingState = .data(loginState(isFavorite: true))
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_login_withAllValues_noPremium() {
        let loginState = loginState(hasPremium: false)
        processor.state.loadingState = .data(loginState)
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_login_withAllValues_noPremium_largeText() {
        let loginState = loginState(hasPremium: false)
        processor.state.loadingState = .data(loginState)
        assertSnapshot(of: subject, as: .tallPortraitAX5(heightMultiple: 5))
    }

    @MainActor
    func disabletest_snapshot_login_withAllValues_largeText() {
        processor.state.loadingState = .data(loginState())
        assertSnapshot(of: subject, as: .tallPortraitAX5(heightMultiple: 5))
    }

    @MainActor
    func disabletest_snapshot_login_withAllValues_exceptTotp_noPremium() {
        let loginState = loginState(hasPremium: false, hasTotp: false)
        processor.state.loadingState = .data(loginState)
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_login_withAllValuesExceptOrganization() {
        var state = loginState(collectionIds: [])
        state.organizationId = nil
        state.organizationName = nil
        state.collectionIds = []
        state.allUserCollections = []
        processor.state.loadingState = .data(state)
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    @MainActor
    func disabletest_snapshot_login_withAllValuesShowMore() {
        let state = loginState(isFavorite: true)
        processor.state.loadingState = .data(state)
        assertSnapshot(of: subject, as: .tallPortrait)
    }

    /// Snapshots the previews for card types.
    @MainActor
    func disabletest_snapshot_previews_card() {
        assertSnapshot(
            of: ViewItemView_Previews.cardPreview,
            as: .defaultPortrait,
        )
    }

    /// Snapshots the previews for card types.
    @MainActor
    func disabletest_snapshot_previews_card_dark() {
        assertSnapshot(
            of: ViewItemView_Previews.cardPreview,
            as: .defaultPortraitDark,
        )
    }

    /// Snapshots the previews for card types.
    @MainActor
    func disabletest_snapshot_previews_card_largeText() {
        assertSnapshot(
            of: ViewItemView_Previews.cardPreview,
            as: .tallPortraitAX5(heightMultiple: 3),
        )
    }

    /// Snapshots the previews for login types.
    @MainActor
    func disabletest_snapshot_previews_login() {
        assertSnapshot(
            of: ViewItemView_Previews.loginPreview,
            as: .tallPortrait,
        )
    }

    /// Snapshots the previews for login types.
    @MainActor
    func disabletest_snapshot_previews_login_dark() {
        assertSnapshot(
            of: ViewItemView_Previews.loginPreview,
            as: .portraitDark(heightMultiple: 2),
        )
    }

    /// Snapshots the previews for login types.
    @MainActor
    func disabletest_snapshot_previews_login_largeText() {
        assertSnapshot(
            of: ViewItemView_Previews.loginPreview,
            as: .tallPortraitAX5(heightMultiple: 4),
        )
    }

    /// Snapshots the previews for secure note types.
    @MainActor
    func disabletest_snapshot_previews_secureNote() {
        assertSnapshot(
            of: ViewItemView_Previews.secureNotePreview,
            as: .defaultPortrait,
        )
    }

    /// Snapshots the previews for login types.
    @MainActor
    func disabletest_snapshot_previews_sshKey() {
        assertSnapshot(
            of: ViewItemView_Previews.sshKeyPreview,
            as: .tallPortrait,
        )
    }

    /// Snapshots the previews for SSH key type.
    @MainActor
    func disabletest_snapshot_sshKey() {
        processor.state.loadingState =
            .data(
                sshKeyCipherItemState(
                    canViewPrivateKey: true,
                    isPrivateKeyVisible: false,
                ),
            )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Snapshots the previews for SSH key type when private key is visible.
    @MainActor
    func disabletest_snapshot_sshKeyPrivateKeyVisible() {
        processor.state.loadingState =
            .data(
                sshKeyCipherItemState(
                    canViewPrivateKey: true,
                    isPrivateKeyVisible: true,
                ),
            )
        assertSnapshots(
            of: subject,
            as: [.defaultPortrait, .defaultPortraitDark, .defaultPortraitAX5],
        )
    }

    /// Snapshots the previews for SSH key type when `canViewPrivateKey` is `false`.
    @MainActor
    func disabletest_snapshot_sshKeyCantViewPrivateKey() {
        processor.state.loadingState =
            .data(
                sshKeyCipherItemState(
                    canViewPrivateKey: false,
                    isPrivateKeyVisible: false,
                ),
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
    ///   - isPrivateKeyVisible: Whether the private key is visible
    /// - Returns: The `CipherItemState` for SSH key item.
    private func sshKeyCipherItemState(canViewPrivateKey: Bool, isPrivateKeyVisible: Bool) -> CipherItemState {
        var state = CipherItemState(
            existing: .fixture(
                id: "fake-id",
                type: .sshKey,
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
}
