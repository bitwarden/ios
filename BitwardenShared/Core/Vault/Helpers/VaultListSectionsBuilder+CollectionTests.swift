// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import InlineSnapshotTesting
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - VaultListSectionsBuilderCollectionTests

class VaultListSectionsBuilderCollectionTests: BitwardenTestCase {
    // MARK: Properties

    var clientService: MockClientService!
    var collectionHelper: MockCollectionHelper!
    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var subject: DefaultVaultListSectionsBuilder!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        collectionHelper = MockCollectionHelper()
        configService = MockConfigService()
        errorReporter = MockErrorReporter()
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
        collectionHelper = nil
        configService = nil
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
                    .fixture(id: "4", organizationId: "1", name: "zcollection9", type: .defaultUserCollection),
                ],
                collectionCipherIds: [
                    "1": .cipherIds(20, prefix: "collection1"),
                    "2": .cipherIds(5, prefix: "collection2"),
                ],
            ),
        )
        collectionHelper.orderReturnValue = [
            .fixture(id: "4", name: "zcollection9", organizationId: "1", type: .defaultUserCollection),
            .fixture(id: "2", name: "acollection2", organizationId: "1"),
            .fixture(id: "1", name: "collection1", organizationId: "1"),
            .fixture(id: "3", name: "collection3", organizationId: "1"),
        ]

        let vaultListData = try await subject.addCollectionsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Collections]: Collections
              - Group[4]: zcollection9 (0)
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
                collectionCipherIds: [
                    "1": .cipherIds(20, prefix: "collection1"),
                    "2": .cipherIds(5, prefix: "collection2"),
                ],
            ),
        )
        collectionHelper.orderReturnValue = [
            .fixture(id: "2", name: "acollection2", organizationId: "1"),
            .fixture(id: nil, name: "collection1", organizationId: "1"),
        ]

        let vaultListData = try await subject.addCollectionsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Collections]: Collections
              - Group[2]: acollection2 (5)
            """
        }
        XCTAssertEqual(
            errorReporter.errors.first as? NSError,
            BitwardenError.dataError("Received a collection from the API with a missing ID."),
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
                collectionCipherIds: [
                    "1": .cipherIds(20, prefix: "collection1"),
                    "2": .cipherIds(5, prefix: "collection2"),
                ],
            ),
        )
        collectionHelper.orderReturnValue = [
            .fixture(id: nil, name: "acollection2", organizationId: "1"),
            .fixture(id: nil, name: "collection1", organizationId: "1"),
        ]

        let vaultListData = try await subject.addCollectionsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            """
        }
        XCTAssertEqual(
            errorReporter.errors.first as? NSError,
            BitwardenError.dataError("Received a collection from the API with a missing ID."),
        )
    }

    /// `addCollectionsSection(nestedCollectionId:)` names the section "Shared folders" when the
    /// `vfo1-foundation` feature flag is enabled.
    @MainActor
    func test_addCollectionsSection_vfo1FoundationEnabled() async throws {
        configService.featureFlagsBool[.vfo1Foundation] = true
        setUpSubject(
            withData: VaultListPreparedData(
                collections: [
                    .fixture(id: "1", organizationId: "1", name: "collection1"),
                ],
            ),
        )
        collectionHelper.orderReturnValue = [
            .fixture(id: "1", name: "collection1", organizationId: "1"),
        ]

        let vaultListData = try await subject.addCollectionsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Collections]: Shared folders
              - Group[1]: collection1 (0)
            """
        }
    }

    /// `addCollectionsSection(nestedCollectionId:)` adds the collection section to the list of sections
    /// with the count of ciphers per collection under the nested collection ID, including the unique
    /// ciphers of each collection's descendant collections.
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
                collectionCipherIds: [
                    "3": .cipherIds(15, prefix: "collection3"),
                    "4": .cipherIds(6, prefix: "collection4"),
                    "5": ["collection4-cipher-0", "collection5-cipher-0"],
                ],
            ),
        )
        collectionHelper.orderReturnValue = [
            .fixture(id: "2", name: "col2", organizationId: "1"),
            .fixture(id: "3", name: "col2/sub1", organizationId: "1"),
            .fixture(id: "4", name: "col2/sub2", organizationId: "1"),
            .fixture(id: "5", name: "col2/sub2/sub1", organizationId: "1"),
            .fixture(id: "1", name: "collection1", organizationId: "1"),
        ]

        let vaultListData = try await subject.addCollectionsSection(nestedCollectionId: "2").build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Collections]: Collections
              - Group[3]: sub1 (15)
              - Group[4]: sub2 (7)
            """
        }
    }

    /// `addCollectionsSection(nestedCollectionId:)` includes the unique ciphers of all descendant
    /// collections at any depth in a collection's count.
    func test_addCollectionsSection_countIncludesDescendantCollections() async throws {
        setUpSubject(
            withData: VaultListPreparedData(
                collections: [
                    .fixture(id: "1", organizationId: "1", name: "C1"),
                    .fixture(id: "2", organizationId: "1", name: "C1/Child1"),
                    .fixture(id: "3", organizationId: "1", name: "C1/Child1/Grandchild"),
                    .fixture(id: "4", organizationId: "1", name: "C1/Child2"),
                ],
                collectionCipherIds: [
                    "1": ["a", "b", "c", "d"],
                    "2": ["e", "f"],
                    "3": ["g", "h"],
                    "4": ["d", "i"],
                ],
            ),
        )
        collectionHelper.orderReturnValue = [
            .fixture(id: "1", name: "C1", organizationId: "1"),
            .fixture(id: "2", name: "C1/Child1", organizationId: "1"),
            .fixture(id: "3", name: "C1/Child1/Grandchild", organizationId: "1"),
            .fixture(id: "4", name: "C1/Child2", organizationId: "1"),
        ]

        let vaultListData = try await subject.addCollectionsSection().build()

        assertInlineSnapshot(of: vaultListData.sections.dump(), as: .lines) {
            """
            Section[Collections]: Collections
              - Group[1]: C1 (9)
            """
        }
    }

    // MARK: Private

    /// Sets up the subject with the appropriate `VaultListPreparedData`.
    func setUpSubject(withData: VaultListPreparedData) {
        subject = DefaultVaultListSectionsBuilder(
            clientService: clientService,
            collectionHelper: collectionHelper,
            configService: configService,
            errorReporter: errorReporter,
            stateService: MockStateService(),
            withData: withData,
        )
    }
}
