// swiftlint:disable:this file_name

import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - VaultListPreparedDataBuilderAddItemTests

class VaultListPreparedDataBuilderAddItemTests: BitwardenTestCase {
    // MARK: Properties

    var clientService: MockClientService!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: DefaultVaultListPreparedDataBuilder!
    var timeProvider: MockTimeProvider!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        timeProvider = MockTimeProvider(.currentTime)
        subject = DefaultVaultListPreparedDataBuilder(
            clientService: clientService,
            errorReporter: errorReporter,
            stateService: stateService,
            timeProvider: timeProvider
        )
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
        errorReporter = nil
        stateService = nil
        timeProvider = nil
        subject = nil
    }

    // MARK: Tests

    /// `addItem(forGroup:with:)` adds a trash item to the prepared data when the cipher is deleted and group is trash.
    func test_addItem_addsTrashItemWhenCipherIsDeletedAndGroupIsTrash() async {
        let cipher = CipherListView.fixture(deletedDate: Date())
        let preparedData = await subject.addItem(forGroup: .trash, with: cipher).build()

        XCTAssertEqual(preparedData.groupItems.count, 1)
        XCTAssertEqual(preparedData.groupItems[0].id, cipher.id)
    }

    /// `addItem(forGroup:with:)` does not add an item when the cipher is deleted and group is not trash.
    func test_addItem_doesNotAddWhenCipherIsDeletedAndGroupIsNotTrash() async {
        let cipher = CipherListView.fixture(deletedDate: Date())
        let preparedData = await subject.addItem(forGroup: .login, with: cipher).build()

        XCTAssertTrue(preparedData.groupItems.isEmpty)
    }

    /// `addItem(forGroup:with:)` adds a login item to the prepared data when the cipher is a login and group is login.
    func test_addItem_addsLoginItemWhenCipherIsLoginAndGroupIsLogin() async {
        let cipher = CipherListView.fixture(type: .login(.fixture()))
        let preparedData = await subject.addItem(forGroup: .login, with: cipher).build()

        XCTAssertEqual(preparedData.groupItems.count, 1)
        XCTAssertEqual(preparedData.groupItems[0].id, cipher.id)
    }

    /// `addItem(forGroup:with:)` does not add an item when the cipher type does not match the group.
    func test_addItem_doesNotAddWhenCipherTypeDoesNotMatchGroup() async {
        let cipher = CipherListView.fixture(type: .card(.fixture()))
        let preparedData = await subject.addItem(forGroup: .login, with: cipher).build()

        XCTAssertTrue(preparedData.groupItems.isEmpty)
    }

    /// `addItem(forGroup:with:)` adds a card item to the prepared data when the cipher is a card and group is card.
    func test_addItem_addsCardItemWhenCipherIsCardAndGroupIsCard() async {
        let cipher = CipherListView.fixture(type: .card(.fixture()))
        let preparedData = await subject.addItem(forGroup: .card, with: cipher).build()

        XCTAssertEqual(preparedData.groupItems.count, 1)
        XCTAssertEqual(preparedData.groupItems[0].id, cipher.id)
    }

    /// `addItem(forGroup:with:)` does not add a card item when the cipher is not a card and group is card.
    func test_addItem_doesNotAddCardItemWhenCipherIsNotCardAndGroupIsCard() async {
        let cipher = CipherListView.fixture(type: .login(.fixture()))
        let preparedData = await subject.addItem(forGroup: .card, with: cipher).build()

        XCTAssertTrue(preparedData.groupItems.isEmpty)
    }

    /// `addItem(forGroup:with:)` adds an identity item to the prepared data when the cipher is an identity
    /// and group is identity.
    func test_addItem_addsIdentityItemWhenCipherIsIdentityAndGroupIsIdentity() async {
        let cipher = CipherListView.fixture(type: .identity)
        let preparedData = await subject.addItem(forGroup: .identity, with: cipher).build()

        XCTAssertEqual(preparedData.groupItems.count, 1)
        XCTAssertEqual(preparedData.groupItems[0].id, cipher.id)
    }

    /// `addItem(forGroup:with:)` does not add an identity item when the cipher is not an identity
    /// and group is identity.
    func test_addItem_doesNotAddIdentityItemWhenCipherIsNotIdentityAndGroupIsIdentity() async {
        let cipher = CipherListView.fixture(type: .login(.fixture()))
        let preparedData = await subject.addItem(forGroup: .identity, with: cipher).build()

        XCTAssertTrue(preparedData.groupItems.isEmpty)
    }

    /// `addItem(forGroup:with:)` adds a secure note item to the prepared data when the cipher is a secure note
    /// and group is secureNote.
    func test_addItem_addsSecureNoteItemWhenCipherIsSecureNoteAndGroupIsSecureNote() async {
        let cipher = CipherListView.fixture(type: .secureNote)
        let preparedData = await subject.addItem(forGroup: .secureNote, with: cipher).build()

        XCTAssertEqual(preparedData.groupItems.count, 1)
        XCTAssertEqual(preparedData.groupItems[0].id, cipher.id)
    }

    /// `addItem(forGroup:with:)` does not add a secure note item when the cipher is not a secure note
    /// and group is secureNote.
    func test_addItem_doesNotAddSecureNoteItemWhenCipherIsNotSecureNoteAndGroupIsSecureNote() async {
        let cipher = CipherListView.fixture(type: .login(.fixture()))
        let preparedData = await subject.addItem(forGroup: .secureNote, with: cipher).build()

        XCTAssertTrue(preparedData.groupItems.isEmpty)
    }

    /// `addItem(forGroup:with:)` adds an SSH key item to the prepared data when the cipher is an SSH key
    /// sand group is sshKey.
    func test_addItem_addsSSHKeyItemWhenCipherIsSSHKeyAndGroupIsSSHKey() async {
        let cipher = CipherListView.fixture(type: .sshKey)
        let preparedData = await subject.addItem(forGroup: .sshKey, with: cipher).build()

        XCTAssertEqual(preparedData.groupItems.count, 1)
        XCTAssertEqual(preparedData.groupItems[0].id, cipher.id)
    }

    /// `addItem(forGroup:with:)` does not add an SSH key item when the cipher is not an SSH key and group is sshKey.
    func test_addItem_doesNotAddSSHKeyItemWhenCipherIsNotSSHKeyAndGroupIsSSHKey() async {
        let cipher = CipherListView.fixture(type: .login(.fixture()))
        let preparedData = await subject.addItem(forGroup: .sshKey, with: cipher).build()

        XCTAssertTrue(preparedData.groupItems.isEmpty)
    }

    /// `addItem(forGroup:with:)` adds a TOTP item to the prepared data when cipher has TOTP, user has access
    /// and code generation succeeds.
    func test_addItem_addsTotpItemWhenCipherHasTotpAndAccessAndCodeGenerationSucceeds() async {
        let cipher = CipherListView.fixture(id: "1", type: .login(.fixture(totp: "123456")))
        stateService.doesActiveAccountHavePremiumResult = true
        clientService.mockVault.generateTOTPCodeResult = .success("654321")

        let preparedData = await subject.addItem(forGroup: .totp, with: cipher).build()

        XCTAssertEqual(preparedData.groupItems.count, 1)
        if case let .totp(_, totpModel) = preparedData.groupItems[0].itemType {
            XCTAssertEqual(totpModel.totpCode.code, "654321")
            XCTAssertEqual(totpModel.id, "1")
        } else {
            XCTFail("Expected .totp item type")
        }
    }

    /// `addItem(forGroup:with:)` does not add a TOTP item when cipher does not have TOTP.
    func test_addItem_doesNotAddTotpItemWhenCipherDoesNotHaveTotp() async {
        let cipher = CipherListView.fixture(id: "1", type: .login(.fixture(totp: nil)))
        stateService.doesActiveAccountHavePremiumResult = true

        let preparedData = await subject.addItem(forGroup: .totp, with: cipher).build()

        XCTAssertTrue(preparedData.groupItems.isEmpty)
    }

    /// `addItem(forGroup:with:)` does not add a TOTP item when user does not have access.
    func test_addItem_doesNotAddTotpItemWhenNoAccess() async {
        let cipher = CipherListView.fixture(id: "1", type: .login(.fixture(totp: "123456")), organizationUseTotp: false)
        stateService.doesActiveAccountHavePremiumResult = false

        let preparedData = await subject.addItem(forGroup: .totp, with: cipher).build()

        XCTAssertTrue(preparedData.groupItems.isEmpty)
    }

    /// `addItem(forGroup:with:)` does not add a TOTP item when code generation fails.
    func test_addItem_doesNotAddTotpItemWhenCodeGenerationFails() async {
        let cipher = CipherListView.fixture(id: "1", type: .login(.fixture(totp: "123456")))
        stateService.doesActiveAccountHavePremiumResult = true
        clientService.mockVault.generateTOTPCodeResult = .failure(TOTPServiceError.unableToGenerateCode("fail"))

        let preparedData = await subject.addItem(forGroup: .totp, with: cipher).build()

        XCTAssertTrue(preparedData.groupItems.isEmpty)
        XCTAssertTrue(errorReporter.errors.contains { ($0 as? TOTPServiceError) != nil })
    }

    /// `addItem(forGroup:with:)` adds a TOTP item when cipher is in an org with TOTP enabled
    /// and code generation succeeds.
    func test_addItem_addsTotpItemWhenOrgHasTotpEnabled() async {
        let cipher = CipherListView.fixture(id: "1", type: .login(.fixture(totp: "123456")), organizationUseTotp: true)
        stateService.doesActiveAccountHavePremiumResult = false
        clientService.mockVault.generateTOTPCodeResult = .success("654321")

        let preparedData = await subject.addItem(forGroup: .totp, with: cipher).build()

        XCTAssertEqual(preparedData.groupItems.count, 1)
        if case let .totp(_, totpModel) = preparedData.groupItems[0].itemType {
            XCTAssertEqual(totpModel.totpCode.code, "654321")
            XCTAssertEqual(totpModel.id, "1")
        } else {
            XCTFail("Expected .totp item type")
        }
    }

    /// `addItem(forGroup:with:)` adds a collection item when the cipher belongs to the collection group.
    func test_addItem_addsCollectionItemWhenCipherInCollectionGroup() async {
        let cipher = CipherListView.fixture(collectionIds: ["col1"])
        let preparedData = await subject.addItem(
            forGroup: .collection(id: "col1", name: "C1", organizationId: "1"),
            with: cipher
        ).build()

        XCTAssertEqual(preparedData.groupItems.count, 1)
        XCTAssertEqual(preparedData.groupItems[0].id, cipher.id)
    }

    /// `addItem(forGroup:with:)` does not add a collection item when the cipher does not belong
    /// to the collection group.
    func test_addItem_doesNotAddCollectionItemWhenCipherNotInCollectionGroup() async {
        let cipher = CipherListView.fixture(collectionIds: ["col2"])
        let preparedData = await subject.addItem(
            forGroup: .collection(id: "col1", name: "C1", organizationId: "1"),
            with: cipher
        ).build()

        XCTAssertTrue(preparedData.groupItems.isEmpty)
    }

    /// `addItem(forGroup:with:)` adds a folder item when the cipher belongs to the folder group.
    func test_addItem_addsFolderItemWhenCipherInFolderGroup() async {
        let cipher = CipherListView.fixture(folderId: "folder1")
        let preparedData = await subject.addItem(
            forGroup: .folder(id: "folder1", name: "F1"),
            with: cipher
        ).build()

        XCTAssertEqual(preparedData.groupItems.count, 1)
        XCTAssertEqual(preparedData.groupItems[0].id, cipher.id)
    }

    /// `addItem(forGroup:with:)` does not add a folder item when the cipher does not belong to the folder group.
    func test_addItem_doesNotAddFolderItemWhenCipherNotInFolderGroup() async {
        let cipher = CipherListView.fixture(folderId: "folder2")
        let preparedData = await subject.addItem(
            forGroup: .folder(id: "folder1", name: "F1"),
            with: cipher
        ).build()

        XCTAssertTrue(preparedData.groupItems.isEmpty)
    }

    /// `addItem(forGroup:with:)` adds a no-folder item when the cipher does not belong to any folder
    /// and group is noFolder.
    func test_addItem_addsNoFolderItemWhenCipherHasNoFolder() async {
        let cipher = CipherListView.fixture(folderId: nil)
        let preparedData = await subject.addItem(forGroup: .noFolder, with: cipher).build()

        XCTAssertEqual(preparedData.groupItems.count, 1)
        XCTAssertEqual(preparedData.groupItems[0].id, cipher.id)
    }

    /// `addItem(forGroup:with:)` does not add a no-folder item when the cipher belongs to a folder
    /// and group is noFolder.
    func test_addItem_doesNotAddNoFolderItemWhenCipherHasFolder() async {
        let cipher = CipherListView.fixture(folderId: "folder1")
        let preparedData = await subject.addItem(forGroup: .noFolder, with: cipher).build()

        XCTAssertTrue(preparedData.groupItems.isEmpty)
    }

    /// `addItem(withMatchResult:cipher:)` with `.exact` match result adds an item to the `exactMatchItems` collection.
    func test_addItem_exactMatchResult() async {
        let cipher = CipherListView.fixture()
        let preparedData = await subject.addItem(withMatchResult: .exact, cipher: cipher).build()

        XCTAssertTrue(preparedData.fuzzyMatchItems.isEmpty)
        XCTAssertEqual(preparedData.exactMatchItems.count, 1)
        XCTAssertEqual(preparedData.exactMatchItems[0].id, cipher.id)
    }

    /// `addItem(withMatchResult:cipher:)` with `.fuzzy` match result adds an item to the `fuzzyMatchItems` collection.
    func test_addItem_fuzzyMatchResult() async {
        let cipher = CipherListView.fixture()
        let preparedData = await subject.addItem(withMatchResult: .fuzzy, cipher: cipher).build()

        XCTAssertTrue(preparedData.exactMatchItems.isEmpty)
        XCTAssertEqual(preparedData.fuzzyMatchItems.count, 1)
        XCTAssertEqual(preparedData.fuzzyMatchItems[0].id, cipher.id)
    }

    /// `addItem(withMatchResult:cipher:)` with `.none` match result doesn't add an item
    ///  to neither the `exactMatchItems` nor the `fuzzyMatchItems` collections.
    func test_addItem_noneMatchResult() async {
        let cipher = CipherListView.fixture()
        let preparedData = await subject.addItem(withMatchResult: .none, cipher: cipher).build()

        XCTAssertTrue(preparedData.exactMatchItems.isEmpty)
        XCTAssertTrue(preparedData.fuzzyMatchItems.isEmpty)
    }
}
