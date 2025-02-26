import BitwardenSdk
import XCTest

@testable import BitwardenShared

class MoveToOrganizationStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `collectionsForOwner` returns the filtered collections based on the selected owner.
    func test_collectionsForOwner() {
        let collectionOrg1 = CollectionView.fixture(id: "1", name: "Collection", organizationId: "1")
        let collectionOrg2 = CollectionView.fixture(id: "2", name: "Collection 2", organizationId: "2")

        var subject = MoveToOrganizationState(cipher: .fixture())
        XCTAssertEqual(subject.collectionsForOwner, [])

        subject.collections = [collectionOrg1, collectionOrg2]
        subject.ownershipOptions = [
            .organization(id: "1", name: "Organization 1"),
            .organization(id: "2", name: "Organization 2"),
        ]

        subject.owner = .organization(id: "1", name: "Organization")
        XCTAssertEqual(subject.collectionsForOwner, [collectionOrg1])

        subject.owner = .organization(id: "2", name: "Organization")
        XCTAssertEqual(subject.collectionsForOwner, [collectionOrg2])
    }

    /// Setting the owner updates the cipher's `organizationId`.`
    func test_owner_updatesOrganizationId() {
        let organization1Owner = CipherOwner.organization(id: "1", name: "Organization")
        let organization2Owner = CipherOwner.organization(id: "2", name: "Organization 2")

        var subject = MoveToOrganizationState(cipher: .fixture())
        subject.ownershipOptions = [organization1Owner, organization2Owner]

        XCTAssertEqual(subject.owner, organization1Owner)
        XCTAssertEqual(subject.organizationId, "1")

        subject.owner = organization2Owner
        XCTAssertEqual(subject.owner, organization2Owner)
        XCTAssertEqual(subject.organizationId, "2")
    }

    /// `toggleCollection(newValue:collectionId:)` toggles whether the cipher is included in the collection.
    func test_toggleCollection() {
        var subject = MoveToOrganizationState(cipher: .fixture())
        subject.collections = [
            .fixture(id: "1", name: "Collection 1"),
            .fixture(id: "2", name: "Collection 2"),
        ]

        subject.toggleCollection(newValue: true, collectionId: "1")
        XCTAssertEqual(subject.collectionIds, ["1"])

        subject.toggleCollection(newValue: true, collectionId: "2")
        XCTAssertEqual(subject.collectionIds, ["1", "2"])

        subject.toggleCollection(newValue: false, collectionId: "1")
        XCTAssertEqual(subject.collectionIds, ["2"])
    }
}
