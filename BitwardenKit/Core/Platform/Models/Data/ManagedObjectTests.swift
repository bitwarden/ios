import BitwardenKit
import CoreData
import XCTest

class ManagedObjectTests: BitwardenTestCase {
    // MARK: Tests

    /// `fetchRequest()` returns a `NSFetchRequest` for the entity.
    func test_fetchRequest() {
        let fetchRequest = TestManagedObject.fetchRequest()
        XCTAssertEqual(fetchRequest.entityName, "TestManagedObject")
    }

    /// `fetchResultRequest()` returns a `NSFetchRequest` for the entity.
    func test_fetchResultRequest() {
        let fetchRequest = TestManagedObject.fetchResultRequest()
        XCTAssertEqual(fetchRequest.entityName, "TestManagedObject")
    }
}

private class TestManagedObject: NSManagedObject, ManagedObject {
    static var entityName = "TestManagedObject"
}
