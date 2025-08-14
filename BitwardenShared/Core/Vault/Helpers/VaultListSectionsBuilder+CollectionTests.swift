// swiftlint:disable:this file_name

import BitwardenKitMocks
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared

// MARK: - VaultListSectionsBuilderCollectionTests

class VaultListSectionsBuilderCollectionTests: BitwardenTestCase {
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

    /// `addCollectionsSection(nestedCollectionId:)` adds the collection section to the list of sections
    /// with the count of ciphers per collection.
    func test_addCollectionsSection_noNestedCollectionId() async throws {
        setUpSubject(
            withData: VaultListPreparedData(
                collections: [
                    .fixture(id: "1", organizationId: "1", name: "collection1"),
                    .fixture(id: "2", organizationId: "1", name: "acollection2"),
                    .fixture(id: "3", organizationId: "1", name: "collection3"),
                ],
                collectionsCount: [
                    "1": 20,
                    "2": 5,
                ]
            )
        )

        let vaultListData = try await subject.addCollectionsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Collections]: Collections
              - Group[2]: acollection2 (5)
              - Group[1]: collection1 (20)
              - Group[3]: collection3 (0)
            """
        }
    }

    /// `addCollectionsSection(nestedCollectionId:)` adds the collection section to the list of sections
    /// with the count of ciphers per collection. However, given that one of them has `nil` ID, it's ignored and
    /// a error is logged.
    func test_addCollectionsSection_noNestedCollectionIdWithCollectionIdNil() async throws {
        setUpSubject(
            withData: VaultListPreparedData(
                collections: [
                    .fixture(id: nil, organizationId: "1", name: "collection1"),
                    .fixture(id: "2", organizationId: "1", name: "acollection2"),
                ],
                collectionsCount: [
                    "1": 20,
                    "2": 5,
                ]
            )
        )

        let vaultListData = try await subject.addCollectionsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Collections]: Collections
              - Group[2]: acollection2 (5)
            """
        }
        XCTAssertEqual(
            errorReporter.errors.first as? NSError,
            BitwardenError.dataError("Received a collection from the API with a missing ID.")
        )
    }

    /// `addCollectionsSection(nestedCollectionId:)` doesn't add the collection section when there are no collection
    /// items after filtering. In this case because all collection have `nil` Id.
    func test_addCollectionsSection_noNestedCollectionIdWithAllCollectionsIdNil() async throws {
        setUpSubject(
            withData: VaultListPreparedData(
                collections: [
                    .fixture(id: nil, organizationId: "1", name: "collection1"),
                    .fixture(id: nil, organizationId: "1", name: "acollection2"),
                ],
                collectionsCount: [
                    "1": 20,
                    "2": 5,
                ]
            )
        )

        let vaultListData = try await subject.addCollectionsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            """
        }
        XCTAssertEqual(
            errorReporter.errors.first as? NSError,
            BitwardenError.dataError("Received a collection from the API with a missing ID.")
        )
    }

    /// `addCollectionsSection(nestedCollectionId:)` adds the collection section to the list of sections
    /// with the count of ciphers per collection under the nested collection ID.
    func test_addCollectionsSection_withNestedCollectionId() async throws {
        setUpSubject(
            withData: VaultListPreparedData(
                collections: [
                    .fixture(id: "1", organizationId: "1", name: "collection1"),
                    .fixture(id: "2", organizationId: "1", name: "col2"),
                    .fixture(id: "3", organizationId: "1", name: "col2/sub1"),
                    .fixture(id: "4", organizationId: "1", name: "col2/sub2"),
                    .fixture(id: "5", organizationId: "1", name: "col2/sub2/sub1"),
                ],
                collectionsCount: [
                    "3": 15,
                    "4": 6,
                ]
            )
        )

        let vaultListData = try await subject.addCollectionsSection(nestedCollectionId: "2").build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Collections]: Collections
              - Group[3]: sub1 (15)
              - Group[4]: sub2 (6)
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
