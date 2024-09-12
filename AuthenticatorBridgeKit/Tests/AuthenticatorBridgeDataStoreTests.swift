import Foundation
import XCTest

@testable import AuthenticatorBridgeKit

final class AuthenticatorBridgeDataStoreTests: XCTestCase {
    // MARK: Properties

    let accessGroup = "group.com.example.bitwarden-authenticator"
    var subject: AuthenticatorBridgeDataStore!
    var error: Error?

    // MARK: Setup & Teardown

    override func setUp() {
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
    }

    // MARK: Tests


    /// Verify that the `deleteAllForUserId` method successfully deletes all of the data for a given userId from the store.
    /// Verify that it does NOT delete the data for a different userId
    ///
    func testDeleteAllForUserId() async throws {
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
    func testFetchAllForUserId() async throws {
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

    /// Verify that the fetchById request correctly finds the item with the given userId and id.
    ///
    func testFetchById() async throws {
        let expectedItems = AuthenticatorBridgeItemDataModel.fixtures()
        let expectedItem = expectedItems[3]
        let insertRequest = try AuthenticatorBridgeItemData.batchInsertRequest(
            objects: expectedItems,
            userId: "userId"
        )
        try subject.persistentContainer.viewContext.executeAndMergeChanges(batchInsertRequest: insertRequest)

        let fetchRequest = AuthenticatorBridgeItemData.fetchByIdRequest(id: expectedItem.id, userId: "userId")
        let result = try subject.persistentContainer.viewContext.fetch(fetchRequest)

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 1)

        let item = try XCTUnwrap(result.first?.model)
        XCTAssertEqual(item, expectedItem)
    }

    /// Verify that the Batch Delete Request successfully deletes all of the data for a given userId from the store.
    /// Verify that it does NOT delete the data for a different userId
    ///
    func testFetchByUserIdRequest() async throws {
        // Insert items for "userId"
        let expectedItems = AuthenticatorBridgeItemDataModel.fixtures().sorted { $0.id < $1.id }
        try await subject.replaceAllItems(with: expectedItems, forUserId: "userId")

        // Separate Insert for "differentUserId"
        let differentUserItem = AuthenticatorBridgeItemDataModel.fixture()
        try await subject.replaceAllItems(with: [differentUserItem], forUserId: "differentUserId")

        // Verify items returned for "userId" do not contain items from "differentUserId"
        let fetchRequest = AuthenticatorBridgeItemData.fetchByUserIdRequest(userId: "userId")
        let result = try subject.persistentContainer.viewContext.fetch(fetchRequest)

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, expectedItems.count)

        /// None of the items for userId should contain the item inserted for differentUserId
        let emptyResult = result.filter { $0.id == differentUserItem.id }
        XCTAssertEqual(emptyResult.count, 0)
    }
}
