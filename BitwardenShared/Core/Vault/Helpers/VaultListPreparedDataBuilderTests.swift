import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - VaultListPreparedDataBuilderTests

class VaultListPreparedDataBuilderTests: BitwardenTestCase {
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
}
