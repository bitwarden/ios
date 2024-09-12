import Foundation
import XCTest

@testable import AuthenticatorBridgeKit

final class AuthenticatorBridgeItemDataTests: XCTestCase {
    // MARK: Properties

    let accessGroup = "group.com.example.bitwarden-authenticator"
    var dataStore: AuthenticatorBridgeDataStore!
    var error: Error?
    var subject: AuthenticatorBridgeItemData!

    // MARK: Setup & Teardown

    override func setUp() {
        let errorHandler: (Error) -> Void = { error in
            self.error = error
        }
        dataStore = AuthenticatorBridgeDataStore(
            storeType: .memory,
            groupIdentifier: accessGroup,
            errorHandler: errorHandler
        )
    }

    override func tearDown() {
        dataStore = nil
        error = nil
        subject = nil
    }

    // MARK: Tests
    /// Verify that creating an `AuthenticatorBridgeItemData` succeeds and returns the expected modelData
    /// correctly coded.
    ///
    func testCreateAndVeryifyData() async throws {
        subject = try AuthenticatorBridgeItemData(
            context: dataStore.persistentContainer.viewContext,
            userId: "userId",
            authenticatorItem: AuthenticatorBridgeItemDataModel(
                favorite: true, id: "is", name: "name", totpKey: "TOTP Key", username: "username"
            )
        )

        let modelData = try XCTUnwrap(subject.modelData)
        let model = try JSONDecoder().decode(AuthenticatorBridgeItemDataModel.self, from: modelData)

        XCTAssertEqual(try? subject.model, model)
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
        try dataStore.persistentContainer.viewContext.executeAndMergeChanges(batchInsertRequest: insertRequest)

        let fetchRequest = AuthenticatorBridgeItemData.fetchByIdRequest(id: expectedItem.id, userId: "userId")
        let result = try dataStore.persistentContainer.viewContext.fetch(fetchRequest)

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 1)

        let item = try XCTUnwrap(result.first?.model)
        XCTAssertEqual(item, expectedItem)
    }

    /// Verify that updating an `AuthenticatorBridgeItemData` successfully updates the model's contents
    ///
    func testUpdates() async throws {
        subject = try AuthenticatorBridgeItemData(
            context: dataStore.persistentContainer.viewContext,
            userId: "userId",
            authenticatorItem: AuthenticatorBridgeItemDataModel(
                favorite: true, id: "id", name: "name", totpKey: "TOTP Key", username: "username"
            )
        )

        let model = AuthenticatorBridgeItemDataModel(
            favorite: false, id: "newId", name: "newName", totpKey: "new TOTP Key", username: "new username"
        )

        try? subject.update(with: model, userId: "newUserId")

        XCTAssertEqual(try? subject.model, model)
        XCTAssertEqual(subject.userId, "newUserId")
    }
}
