import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - CollectionHelperTests

class CollectionHelperTests: BitwardenTestCase {
    // MARK: Properties

    var organizationService: MockOrganizationService!
    var subject: DefaultCollectionHelper!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        organizationService = MockOrganizationService()
        subject = DefaultCollectionHelper(organizationService: organizationService)
    }

    override func tearDown() {
        super.tearDown()

        organizationService = nil
        subject = nil
    }

    // MARK: Tests

    /// `order(_:)` orders collections by name when there's no default collection.
    func test_order_noDefaultCollection() async throws {
        let unorderedCollections: [CollectionView] = [
            .fixture(id: "1", name: "Collection 3", type: .sharedCollection),
            .fixture(id: "2", name: "Collection 2", type: .sharedCollection),
            .fixture(id: "3", name: "Collection 1", type: .sharedCollection),
        ]
        let collections = try await subject.order(unorderedCollections)

        XCTAssertEqual(
            collections.map(\.name),
            [
                "Collection 1",
                "Collection 2",
                "Collection 3",
            ],
        )
        XCTAssertFalse(organizationService.fetchAllOrganizationsCalled)
    }

    /// `order(_:)` orders collections by type and then by name when there's only
    /// one default collection.
    func test_order_oneDefaultCollection() async throws {
        let unorderedCollections: [CollectionView] = [
            .fixture(id: "1", name: "Collection 3", type: .sharedCollection),
            .fixture(id: "2", name: "Collection 2", type: .defaultUserCollection),
            .fixture(id: "3", name: "Collection 1", type: .sharedCollection),
        ]
        let collections = try await subject.order(unorderedCollections)

        XCTAssertEqual(
            collections.map(\.name),
            [
                "Collection 2",
                "Collection 1",
                "Collection 3",
            ],
        )
        XCTAssertFalse(organizationService.fetchAllOrganizationsCalled)
    }

    /// `order(_:)` orders collections by type, then by organization name and then by name when there are multiple
    /// default collections.
    func test_order_multipleDefaultCollection() async throws {
        let unorderedCollections: [CollectionView] = [
            .fixture(id: "1", name: "Collection 3", organizationId: "2", type: .sharedCollection),
            .fixture(id: "2", name: "My Items", organizationId: "3", type: .defaultUserCollection),
            .fixture(id: "3", name: "My Items", organizationId: "2", type: .defaultUserCollection),
            .fixture(id: "4", name: "Collection 1", organizationId: "3", type: .sharedCollection),
        ]
        organizationService.fetchAllOrganizationsResult = .success([
            .fixture(id: "1", name: "First in alphabetical order"),
            .fixture(id: "2", name: "Second in alphabetical order"),
            .fixture(id: "3", name: "Third in alphabetical order"),
        ])

        let collections = try await subject.order(unorderedCollections)

        XCTAssertEqual(
            collections.map { "[\($0.id ?? "nil")] \($0.name)" },
            [
                "[3] My Items",
                "[2] My Items",
                "[4] Collection 1",
                "[1] Collection 3",
            ],
        )
    }
}
