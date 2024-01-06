import BitwardenSdk
import XCTest

@testable import BitwardenShared

class EditCollectionsStateTests: BitwardenTestCase {
    // MARK: Tests

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
