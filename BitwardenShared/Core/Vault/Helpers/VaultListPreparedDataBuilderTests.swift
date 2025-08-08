import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

// MARK: - VaultListPreparedDataBuilderTests

class VaultListPreparedDataBuilderTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
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

    /// `addCipherDecryptionFailure(cipher:)` adds the cipher ID to the prepared data when the
    /// cipher failed to decrypt.
    func test_addCipherDecryptionFailure() {
        let cipher = CipherListView(cipherDecryptFailure: .fixture(id: "1"))
        let preparedData = subject.addCipherDecryptionFailure(cipher: cipher).build()

        XCTAssertEqual(preparedData.cipherDecryptionFailureIds, ["1"])
    }

    /// `addCipherDecryptionFailure(cipher:)` doesn't add the cipher ID to the prepared data when
    /// the cipher failed to decrypt.
    func test_addCipherDecryptionFailure_notDecryptFailure() {
        let cipher = CipherListView.fixture()
        let preparedData = subject.addCipherDecryptionFailure(cipher: cipher).build()

        XCTAssertTrue(preparedData.cipherDecryptionFailureIds.isEmpty)
    }

    /// `addFavoriteItem(cipher:)` adds a favorite list item to the prepared data when cipher is favorite.
    func test_addFavoriteItem_succeeds() {
        let cipher = CipherListView.fixture(favorite: true)
        let preparedData = subject.addFavoriteItem(cipher: cipher).build()

        XCTAssertEqual(preparedData.favorites.count, 1)
        XCTAssertEqual(preparedData.favorites[0].id, "1")
    }

    /// `addFavoriteItem(cipher:)` doesn't add a favorite list item to the prepared data when cipher is not favorite.
    func test_addFavoriteItem_notFavorite() {
        let cipher = CipherListView.fixture(favorite: false)
        let preparedData = subject.addFavoriteItem(cipher: cipher).build()

        XCTAssertTrue(preparedData.favorites.isEmpty)
    }

    /// `addFavoriteItem(cipher:)` doesn't add a favorite list item to the prepared data when cipher is favorite
    /// but doesn't have Id.
    func test_addFavoriteItem_favoriteButNilId() {
        let cipher = CipherListView.fixture(id: nil, favorite: true)
        let preparedData = subject.addFavoriteItem(cipher: cipher).build()

        XCTAssertTrue(preparedData.favorites.isEmpty)
    }

    /// `addFolderItem(cipher:filter:folders:)` adds a folder to the prepared data when the cipher belongs
    /// to a folder that is in the list of folders and filtering by `.myVault`.
    func test_addFolderItem_succeeds() {
        let cipher = CipherListView.fixture(folderId: "1")
        let preparedData = subject
            .addFolderItem(
                cipher: cipher,
                filter: VaultListFilter(filterType: .myVault),
                folders: [.fixture(id: "1"), .fixture(id: "2")]
            )
            .build()

        XCTAssertEqual(preparedData.folders.count, 1)
        XCTAssertEqual(preparedData.folders[0].id, "1")
        XCTAssertEqual(preparedData.foldersCount["1"], 1)
    }

    /// `addFolderItem(cipher:filter:folders:)` doesn't add a folder to the prepared data when the cipher doesn't
    /// belong to a folder
    func test_addFolderItem_cipherDoesntBelongToFolder() {
        let cipher = CipherListView.fixture(folderId: nil)
        let preparedData = subject
            .addFolderItem(
                cipher: cipher,
                filter: VaultListFilter(filterType: .myVault),
                folders: [.fixture(id: "1"), .fixture(id: "2")]
            )
            .build()

        XCTAssertTrue(preparedData.folders.isEmpty)
        XCTAssertTrue(preparedData.foldersCount.isEmpty)
    }

    /// `addFolderItem(cipher:filter:folders:)` doesn't add a folder to the prepared data when the cipher
    /// belongs to a folder but is not in the list of folders passed.
    func test_addFolderItem_cipherDoesntBelongToFolderInList() {
        let cipher = CipherListView.fixture(folderId: "10")
        let preparedData = subject
            .addFolderItem(
                cipher: cipher,
                filter: VaultListFilter(filterType: .myVault),
                folders: [.fixture(id: "1"), .fixture(id: "2")]
            )
            .build()

        XCTAssertTrue(preparedData.folders.isEmpty)
        XCTAssertTrue(preparedData.foldersCount.isEmpty)
    }

    /// `addFolderItem(cipher:filter:folders:)` adds a folder to the prepared data when the ciphers belongs
    /// to a folder that is in the list of folders and filtering by `.myVault`
    /// but it doesn't duplicate it for multiple ciphers.
    func test_addFolderItem_succeedsNotRepeatingAFolderThatHasBeenAddedOnMultipleCiphers() {
        let filter = VaultListFilter(filterType: .myVault)
        let folders: [Folder] = [.fixture(id: "1"), .fixture(id: "2")]
        let preparedData = subject
            .addFolderItem(
                cipher: CipherListView.fixture(id: "1", folderId: "1"),
                filter: filter,
                folders: folders
            )
            .addFolderItem(
                cipher: CipherListView.fixture(id: "2", folderId: "1"),
                filter: filter,
                folders: folders
            )
            .addFolderItem(
                cipher: CipherListView.fixture(id: "3", folderId: "40"),
                filter: filter,
                folders: folders
            )
            .addFolderItem(
                cipher: CipherListView.fixture(id: "4", folderId: "1"),
                filter: filter,
                folders: folders
            )
            .build()

        XCTAssertEqual(preparedData.folders.count, 1)
        XCTAssertEqual(preparedData.folders[0].id, "1")
        XCTAssertEqual(preparedData.foldersCount["1"], 3)
    }

    /// `addNoFolderItem(cipher:)` adds a "no folder" list item to the prepared data when cipher
    /// not belonging to a folder.
    func test_addNoFolderItem_succeeds() {
        let cipher = CipherListView.fixture(folderId: nil)
        let preparedData = subject.addNoFolderItem(cipher: cipher).build()

        XCTAssertEqual(preparedData.noFolderItems.count, 1)
        XCTAssertEqual(preparedData.noFolderItems[0].id, "1")
    }

    /// `addNoFolderItem(cipher:)` doesn't add a "no folder" list item to the prepared data when cipher
    /// belonging to a folder.
    func test_addNoFolderItem_belongsToFolder() {
        let cipher = CipherListView.fixture(folderId: "1")
        let preparedData = subject.addNoFolderItem(cipher: cipher).build()

        XCTAssertTrue(preparedData.noFolderItems.isEmpty)
    }

    /// `addNoFolderItem(cipher:)` doesn't add a "no folder" list item to the prepared data when cipher
    /// not belonging to a folder but not having Id.
    func test_addNoFolderItem_NilId() {
        let cipher = CipherListView.fixture(id: nil, folderId: nil)
        let preparedData = subject.addNoFolderItem(cipher: cipher).build()

        XCTAssertTrue(preparedData.noFolderItems.isEmpty)
    }

    /// `incrementCipherTypeCount(cipher:)` increments count on the correct count per cipher type
    /// depending on the cipher type on the prepared data.
    func test_incrementCipherTypeCount() {
        let preparedData = subject
            .incrementCipherTypeCount(cipher: .fixture(type: .card(.fixture())))
            .incrementCipherTypeCount(cipher: .fixture(type: .card(.fixture())))
            .incrementCipherTypeCount(cipher: .fixture(type: .secureNote))
            .incrementCipherTypeCount(cipher: .fixture(type: .identity))
            .incrementCipherTypeCount(cipher: .fixture(type: .sshKey))
            .incrementCipherTypeCount(cipher: .fixture(type: .login(.fixture())))
            .incrementCipherTypeCount(cipher: .fixture(type: .card(.fixture())))
            .incrementCipherTypeCount(cipher: .fixture(type: .login(.fixture())))
            .incrementCipherTypeCount(cipher: .fixture(type: .secureNote))
            .build()

        XCTAssertEqual(preparedData.countPerCipherType[.card], 3)
        XCTAssertEqual(preparedData.countPerCipherType[.login], 2)
        XCTAssertEqual(preparedData.countPerCipherType[.identity], 1)
        XCTAssertEqual(preparedData.countPerCipherType[.secureNote], 2)
        XCTAssertEqual(preparedData.countPerCipherType[.sshKey], 1)
    }

    /// `incrementCipherDeletedCount()` increments cipher deleted count on the prepared data.
    func test_incrementCipherDeletedCount() {
        let preparedData = subject
            .incrementCipherDeletedCount()
            .incrementCipherDeletedCount()
            .incrementCipherDeletedCount()
            .build()

        XCTAssertEqual(preparedData.ciphersDeletedCount, 3)
    }

    /// `incrementCollectionCount(cipher:)` increments the collection count for the cipher's collection
    /// when the cipher belongs to a collection present in the prepared data.
    func test_incrementCollectionCount_incrementsWhenCipherInCollection() {
        let collection = Collection.fixture(id: "1")
        let cipher = CipherListView.fixture(collectionIds: ["1"])
        let preparedData = subject
            .prepareCollections(collections: [collection], filterType: .allVaults)
            .incrementCollectionCount(cipher: cipher)
            .build()

        XCTAssertEqual(preparedData.collectionsCount["1"], 1)
    }

    /// `incrementCollectionCount(cipher:)` increments the collection count for the cipher's collections
    /// when the cipher belongs to many collections present in the prepared data.
    func test_incrementCollectionCount_incrementsWhenCipherInManyCollection() {
        let collections = [Collection.fixture(id: "1"), Collection.fixture(id: "2")]
        let cipher = CipherListView.fixture(collectionIds: ["1", "2"])
        let preparedData = subject
            .prepareCollections(collections: collections, filterType: .allVaults)
            .incrementCollectionCount(cipher: cipher)
            .build()

        XCTAssertEqual(preparedData.collectionsCount["1"], 1)
        XCTAssertEqual(preparedData.collectionsCount["2"], 1)
    }

    /// `incrementCollectionCount(cipher:)` does not increment the collection count when the cipher
    /// does not belong to any collection.
    func test_incrementCollectionCount_doesNotIncrementWhenCipherHasNoCollection() {
        let collection = Collection.fixture(id: "1")
        let cipher = CipherListView.fixture(collectionIds: [])
        let preparedData = subject
            .prepareCollections(collections: [collection], filterType: .allVaults)
            .incrementCollectionCount(cipher: cipher)
            .build()

        XCTAssertNil(preparedData.collectionsCount["1"])
    }

    /// `incrementCollectionCount(cipher:)` does not increment the collection count when the cipher's collection
    ///  is not present in the prepared data.
    func test_incrementCollectionCount_doesNotIncrementWhenCollectionNotInPreparedData() {
        let collection = Collection.fixture(id: "1")
        let cipher = CipherListView.fixture(collectionIds: ["2"])
        let preparedData = subject
            .prepareCollections(collections: [collection], filterType: .allVaults)
            .incrementCollectionCount(cipher: cipher)
            .build()

        XCTAssertNil(preparedData.collectionsCount["2"])
        XCTAssertNil(preparedData.collectionsCount["1"])
    }

    /// `incrementTOTPCount(cipher:)` increments the TOTP items count when cipher has TOTP and user has access.
    func test_incrementTOTPCount_incrementsWhenCipherHasTOTPAndAccess() async {
        let cipher = CipherListView.fixture(type: .login(.fixture(totp: "123456")))
        stateService.doesActiveAccountHavePremiumResult = true

        let preparedData = await subject.incrementTOTPCount(cipher: cipher).build()

        XCTAssertEqual(preparedData.totpItemsCount, 1)
    }

    /// `incrementTOTPCount(cipher:)` does not increment the TOTP items count when cipher does not have TOTP.
    func test_incrementTOTPCount_doesNotIncrementWhenCipherHasNoTOTP() async {
        let cipher = CipherListView.fixture(type: .login(.fixture(totp: nil)))
        stateService.doesActiveAccountHavePremiumResult = true

        let preparedData = await subject.incrementTOTPCount(cipher: cipher).build()

        XCTAssertEqual(preparedData.totpItemsCount, 0)
    }

    /// `incrementTOTPCount(cipher:)` does not increment the TOTP items count when user does not have premium
    ///  or organiation access.
    func test_incrementTOTPCount_doesNotIncrementWhenNoAccess() async {
        let cipher = CipherListView.fixture(type: .login(.fixture(totp: "123456")), organizationUseTotp: false)
        stateService.doesActiveAccountHavePremiumResult = false

        let preparedData = await subject.incrementTOTPCount(cipher: cipher).build()

        XCTAssertEqual(preparedData.totpItemsCount, 0)
    }

    /// `incrementTOTPCount(cipher:)` does not increment the TOTP items count when user has premium access
    /// but cipher is not a login.
    func test_incrementTOTPCount_doesNotIncrementWhenNotALogin() async {
        let cipher = CipherListView.fixture(type: .secureNote)
        stateService.doesActiveAccountHavePremiumResult = false

        let preparedData = await subject.incrementTOTPCount(cipher: cipher).build()

        XCTAssertEqual(preparedData.totpItemsCount, 0)
    }

    /// `incrementTOTPCount(cipher:)` increments the TOTP items count when cipher is in an organization
    ///  with TOTP enabled.
    func test_incrementTOTPCount_incrementsWhenOrgHasTotpEnabled() async {
        let cipher = CipherListView.fixture(type: .login(.fixture(totp: "123456")), organizationUseTotp: true)
        stateService.doesActiveAccountHavePremiumResult = false

        let preparedData = await subject.incrementTOTPCount(cipher: cipher).build()

        XCTAssertEqual(preparedData.totpItemsCount, 1)
    }

    /// `prepareCollections(collections:filterType:)` adds the collections to the prepared data
    /// when filtering by all vaults.
    func test_prepareCollections_allVaults() {
        let preparedData = subject
            .prepareCollections(
                collections: [.fixture(id: "1"), .fixture(id: "2")],
                filterType: .allVaults
            )
            .build()

        XCTAssertEqual(preparedData.collections.count, 2)
        XCTAssertEqual(preparedData.collections[safeIndex: 0]?.id, "1")
        XCTAssertEqual(preparedData.collections[safeIndex: 1]?.id, "2")
    }

    /// `prepareCollections(collections:filterType:)` adds the proper collections to the prepared data
    /// when filtering by organization.
    func test_prepareCollections_organization() {
        let preparedData = subject
            .prepareCollections(
                collections: [
                    .fixture(id: "1", organizationId: "1"),
                    .fixture(id: "2", organizationId: "7"),
                    .fixture(id: "3", organizationId: "2"),
                    .fixture(id: "4", organizationId: "1"),
                    .fixture(id: "5", organizationId: "1"),
                ],
                filterType: .organization(.fixture(id: "1"))
            )
            .build()

        XCTAssertEqual(preparedData.collections.count, 3)
        XCTAssertEqual(preparedData.collections.map(\.id), ["1", "4", "5"])
    }

    /// `prepareCollections(collections:filterType:)` doesn't add collections to the prepared data
    /// when filtering by my vault.
    func test_prepareCollections_myVault() {
        let preparedData = subject
            .prepareCollections(
                collections: [.fixture(id: "1"), .fixture(id: "2")],
                filterType: .myVault
            )
            .build()

        XCTAssertTrue(preparedData.collections.isEmpty)
    }

    /// `prepareFolders(folders:filterType:)` adds the folders to the prepared data when filtering by all vaults.
    func test_prepareFolders() {
        let preparedData = subject
            .prepareFolders(
                folders: [.fixture(id: "1"), .fixture(id: "2")],
                filterType: .allVaults
            )
            .build()

        XCTAssertEqual(preparedData.folders.count, 2)
        XCTAssertEqual(preparedData.folders[safeIndex: 0]?.id, "1")
        XCTAssertEqual(preparedData.folders[safeIndex: 1]?.id, "2")
    }

    /// `prepareFolders(folders:filterType:)` doesn't add the folders to the prepared data
    /// when filtering by my vault or organization.
    func test_prepareFolders_filterMyVaultOrOrganization() {
        let preparedData = subject
            .prepareFolders(
                folders: [.fixture(id: "1"), .fixture(id: "2")],
                filterType: .myVault
            )
            .prepareFolders(
                folders: [.fixture(id: "1"), .fixture(id: "2")],
                filterType: .organization(.fixture())
            )
            .build()

        XCTAssertTrue(preparedData.folders.isEmpty)
    }

    /// `test_prepareRestrictItemsPolicyOrganizations(restrictedOrganizationIds:)` adds restrictedOrganizationIds
    /// to prepared data
    func test_prepareRestrictItemsPolicyOrganizations() {
        let restrictedOrganizationIds = ["org1", "org2"]
        let preparedData = subject
            .prepareRestrictItemsPolicyOrganizations(restrictedOrganizationIds: restrictedOrganizationIds)
            .build()
        XCTAssertEqual(preparedData.restrictedOrganizationIds, restrictedOrganizationIds)
    }
}
