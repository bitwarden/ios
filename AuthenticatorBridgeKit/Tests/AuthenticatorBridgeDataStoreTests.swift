import Foundation
import XCTest

@testable import AuthenticatorBridgeKit

final class AuthenticatorBridgeDataStoreTests: AuthenticatorBridgeKitTestCase {
    // MARK: Properties

    let accessGroup = "group.com.example.bitwarden-authenticator"
    var subject: AuthenticatorBridgeDataStore!
    var error: Error?

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        let errorHandler: (Error) -> Void = { error in
            self.error = error
        }
        subject = AuthenticatorBridgeDataStore(
            storeType: .memory,
            groupIdentifier: accessGroup,
            errorHandler: errorHandler
        )
    }

    override func tearDown() {
        error = nil
        subject = nil
        super.tearDown()
    }

    // MARK: Tests


    /// Verify that the `deleteAllForUserId` method successfully deletes all of the data for a given userId from the store.
    /// Verify that it does NOT delete the data for a different userId
    ///
    func test_deleteAllForUserId_success() async throws {
        let items = AuthenticatorBridgeItemDataModel.fixtures()

        // First Insert for "userId"
        try await subject.replaceAllItems(with: items, forUserId: "userId")

        // Separate Insert for "differentUserId"
        try await subject.replaceAllItems(with: AuthenticatorBridgeItemDataModel.fixtures(), forUserId: "differentUserId")

        // Remove the items for "differentUserId"
        try await subject.deleteAllForUserId("differentUserId")
        try subject.persistentContainer.viewContext.saveIfChanged()
        try subject.backgroundContext.saveIfChanged()

        // Verify items are removed for "differentUserId"
        let deletedFetchResult = try await subject.fetchAllForUserId("differentUserId")

        XCTAssertNotNil(deletedFetchResult)
        XCTAssertEqual(deletedFetchResult.count, 0)

        // Verify items are still present for "userId"
        let result = try await subject.fetchAllForUserId("userId")

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, items.count)
    }

    /// Verify that the `fetchAllForUserId` method successfully fetches the data for the given user id, and does not
    /// include data for a different user id.
    ///
    func test_fetchAllForUserId_success() async throws {
        // Insert items for "userId"
        let expectedItems = AuthenticatorBridgeItemDataModel.fixtures().sorted { $0.id < $1.id }
        try await subject.replaceAllItems(with: expectedItems, forUserId: "userId")

        // Separate Insert for "differentUserId"
        let differentUserItem = AuthenticatorBridgeItemDataModel.fixture()
        try await subject.replaceAllItems(with: [differentUserItem], forUserId: "differentUserId")

        // Fetch should return only the expectedItem
        let result = try await subject.fetchAllForUserId("userId")

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, expectedItems.count)
        XCTAssertEqual(result, expectedItems)

        // None of the items for userId should contain the item inserted for differentUserId
        let emptyResult = result.filter { $0.id == differentUserItem.id }
        XCTAssertEqual(emptyResult.count, 0)
    }

    /// Verify the `replaceAllItems` correctly deletes all of the items in the store previously when given
    /// an empty list of items to insert for the given userId.
    ///
    func test_replaceAllItems_emptyInsertDeletesExisting() async throws {
        // Insert initial items for "userId"
        let expectedItems = AuthenticatorBridgeItemDataModel.fixtures().sorted { $0.id < $1.id }
        try await subject.replaceAllItems(with: expectedItems, forUserId: "userId")

        // Replace with empty list, deleting all
        try await subject.replaceAllItems(with: [], forUserId: "userId")

        let result = try await subject.fetchAllForUserId("userId")
        XCTAssertEqual(result, [])
    }

    /// Verify the `replaceAllItems` correctly replaces all of the items in the store previously with the new
    /// list of items for the given userId
    ///
    func test_replaceAllItems_replacesExisting() async throws {
        // Insert initial items for "userId"
        let initialItems = [AuthenticatorBridgeItemDataModel.fixture()]
        try await subject.replaceAllItems(with: initialItems, forUserId: "userId")

        // Replace items for "userId"
        let expectedItems = AuthenticatorBridgeItemDataModel.fixtures().sorted { $0.id < $1.id }
        try await subject.replaceAllItems(with: expectedItems, forUserId: "userId")

        let result = try await subject.fetchAllForUserId("userId")

        XCTAssertEqual(result, expectedItems)
        XCTAssertFalse(result.contains { $0 == initialItems.first })
    }

    /// Verify the `replaceAllItems` correctly inserts items when a userId doesn't contain any items in the store previously.
    ///
    func test_replaceAllItems_startingFromEmpty() async throws {
        // Insert items for "userId"
        let expectedItems = AuthenticatorBridgeItemDataModel.fixtures().sorted { $0.id < $1.id }
        try await subject.replaceAllItems(with: expectedItems, forUserId: "userId")

        let result = try await subject.fetchAllForUserId("userId")

        XCTAssertEqual(result, expectedItems)
    }
}
