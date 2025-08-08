// swiftlint:disable:this file_name

import BitwardenKitMocks
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - VaultListSectionsBuilderFolderTests

class VaultListSectionsBuilderFolderTests: BitwardenTestCase {
    // MARK: Properties

    var clientService: MockClientService!
    var errorReporter: MockErrorReporter!
    var subject: DefaultVaultListSectionsBuilder!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        errorReporter = MockErrorReporter()
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
        errorReporter = nil
        subject = nil
    }

    // MARK: Tests

    /// `addFoldersSection(nestedFolderId:)` adds the folders section to the list of sections
    /// with the count of ciphers per folder.
    func test_addFoldersSection_noNestedFolderId() async throws {
        setUpSubject(
            withData: VaultListPreparedData(
                folders: [
                    .fixture(id: "1", name: "folder1"),
                    .fixture(id: "2", name: "afolder2"),
                    .fixture(id: "3", name: "folder3"),
                ],
                foldersCount: [
                    "1": 20,
                    "2": 5,
                ]
            )
        )

        let vaultListData = try await subject.addFoldersSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Folders]: Folders
              - Group[2]: afolder2 (5)
              - Group[1]: folder1 (20)
              - Group[3]: folder3 (0)
            """
        }
    }

    /// `addFoldersSection(nestedFolderId:)` adds the folders section to the list of sections
    /// with the count of ciphers per folder. However, given that one of them has `nil` ID, it's ignored and
    /// a error is logged.
    func test_addFoldersSection_noNestedFolderIdWithAFolderIdNil() async throws {
        setUpSubject(
            withData: VaultListPreparedData(
                folders: [
                    .fixture(id: nil, name: "folder1"),
                    .fixture(id: "2", name: "afolder2"),
                    .fixture(id: "3", name: "folder3"),
                ],
                foldersCount: [
                    "1": 20,
                    "2": 5,
                ]
            )
        )

        let vaultListData = try await subject.addFoldersSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Folders]: Folders
              - Group[2]: afolder2 (5)
              - Group[3]: folder3 (0)
            """
        }
        XCTAssertEqual(
            errorReporter.errors.first as? NSError,
            BitwardenError.dataError("Received a folder from the API with a missing ID.")
        )
    }

    /// `addFoldersSection(nestedFolderId:)` adds the folders section to the list of sections
    /// with the count of ciphers per folder under the nested folder ID.
    func test_addFoldersSection_withNestedFolderId() async throws {
        setUpSubject(
            withData: VaultListPreparedData(
                folders: [
                    .fixture(id: "1", name: "folder1"),
                    .fixture(id: "2", name: "fol2"),
                    .fixture(id: "3", name: "fol2/sub1"),
                    .fixture(id: "4", name: "fol2/sub2"),
                    .fixture(id: "5", name: "fol2/sub2/sub1"),
                ],
                foldersCount: [
                    "3": 15,
                    "4": 6,
                ]
            )
        )

        let vaultListData = try await subject.addFoldersSection(nestedFolderId: "2").build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Folders]: Folders
              - Group[3]: sub1 (15)
              - Group[4]: sub2 (6)
            """
        }
    }

    /// `addFoldersSection(nestedFolderId:)` adds the folders section to the list of sections
    /// with the count of ciphers per folder and the "No Folder" section.
    func test_addFoldersSection_withNoFolderSection() async throws {
        setUpSubject(
            withData: VaultListPreparedData(
                folders: [
                    .fixture(id: "1", name: "folder1"),
                    .fixture(id: "2", name: "afolder2"),
                    .fixture(id: "3", name: "folder3"),
                ],
                foldersCount: [
                    "1": 20,
                    "2": 5,
                ],
                noFolderItems: [
                    .fixture(cipherListView: .fixture(id: "2", name: "Cipher2")),
                    .fixture(cipherListView: .fixture(id: "3", name: "Cipher3")),
                    .fixture(cipherListView: .fixture(id: "1", name: "Cipher1")),
                ]
            )
        )

        let vaultListData = try await subject.addFoldersSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Folders]: Folders
              - Group[2]: afolder2 (5)
              - Group[1]: folder1 (20)
              - Group[3]: folder3 (0)
            Section[NoFolder]: No Folder
              - Cipher: Cipher1
              - Cipher: Cipher2
              - Cipher: Cipher3
            """
        }
    }

    /// `addFoldersSection(:)` adds the "No Folder" section even when there are no
    /// other folders.
    func test_addFoldersSection_noFolderWithEmptyFolders() async throws {
        setUpSubject(
            withData: VaultListPreparedData(
                folders: [],
                noFolderItems: [
                    .fixture(cipherListView: .fixture(id: "2", name: "Cipher2")),
                    .fixture(cipherListView: .fixture(id: "3", name: "Cipher3")),
                    .fixture(cipherListView: .fixture(id: "1", name: "Cipher1")),
                ]
            )
        )

        let vaultListData = try await subject.addFoldersSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[NoFolder]: No Folder
              - Cipher: Cipher1
              - Cipher: Cipher2
              - Cipher: Cipher3
            """
        }
    }

    /// `addFoldersSection(nestedFolderId:)` adds the folders section to the list of sections
    /// with the count of ciphers per folder and a "No Folder" item because there are collections.
    func test_addFoldersSection_withNoFolderItem() async throws {
        setUpSubject(
            withData: VaultListPreparedData(
                collections: [.fixture()],
                folders: [
                    .fixture(id: "1", name: "folder1"),
                    .fixture(id: "2", name: "afolder2"),
                    .fixture(id: "3", name: "folder3"),
                ],
                foldersCount: [
                    "1": 20,
                    "2": 5,
                ],
                noFolderItems: [
                    .fixture(cipherListView: .fixture(id: "1", name: "Cipher1")),
                    .fixture(cipherListView: .fixture(id: "2", name: "Cipher2")),
                    .fixture(cipherListView: .fixture(id: "3", name: "Cipher3")),
                ]
            )
        )

        let vaultListData = try await subject.addFoldersSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Folders]: Folders
              - Group[2]: afolder2 (5)
              - Group[1]: folder1 (20)
              - Group[3]: folder3 (0)
              - Group[NoFolderFolderItem]: No Folder (3)
            """
        }
    }

    /// `addFoldersSection(nestedFolderId:)` adds the folders section to the list of sections
    /// with the count of ciphers per folder and a "No Folder" item because there are more than 100 items.
    func test_addFoldersSection_withNoFolderItemWhenMoreThan100() async throws {
        var noFolderItems: [VaultListItem] = []
        for cipherIndex in 1 ... 101 {
            noFolderItems.append(
                .fixture(cipherListView: .fixture(id: "\(cipherIndex)", name: "Cipher\(cipherIndex)"))
            )
        }
        setUpSubject(
            withData: VaultListPreparedData(
                folders: [
                    .fixture(id: "1", name: "folder1"),
                    .fixture(id: "2", name: "afolder2"),
                    .fixture(id: "3", name: "folder3"),
                ],
                foldersCount: [
                    "1": 20,
                    "2": 5,
                ],
                noFolderItems: noFolderItems
            )
        )

        let vaultListData = try await subject.addFoldersSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Folders]: Folders
              - Group[2]: afolder2 (5)
              - Group[1]: folder1 (20)
              - Group[3]: folder3 (0)
              - Group[NoFolderFolderItem]: No Folder (101)
            """
        }
    }

    // MARK: Private

    /// Sets up the subject with the appropriate `VaultListPreparedData`.
    func setUpSubject(withData: VaultListPreparedData) {
        subject = DefaultVaultListSectionsBuilder(
            clientService: clientService,
            errorReporter: errorReporter,
            withData: withData
        )
    }
}
