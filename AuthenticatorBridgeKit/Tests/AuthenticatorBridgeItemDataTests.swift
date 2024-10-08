import Foundation
import XCTest

@testable import AuthenticatorBridgeKit

final class AuthenticatorBridgeItemDataTests: AuthenticatorBridgeKitTestCase {
    // MARK: Properties

    let accessGroup = "group.com.example.bitwarden-authenticator"
    var cryptoService: MockSharedCryptographyService!
    var dataStore: AuthenticatorBridgeDataStore!
    var errorReporter: ErrorReporter!
    var itemService: AuthenticatorBridgeItemService!
    var subject: AuthenticatorBridgeItemData!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()
        cryptoService = MockSharedCryptographyService()
        errorReporter = MockErrorReporter()
        dataStore = AuthenticatorBridgeDataStore(
            errorReporter: errorReporter,
            groupIdentifier: accessGroup,
            storeType: .memory
        )
        itemService = DefaultAuthenticatorBridgeItemService(
            cryptoService: cryptoService,
            dataStore: dataStore,
            sharedKeychainRepository: MockSharedKeychainRepository()
        )
    }

    override func tearDown() {
        cryptoService = nil
        dataStore = nil
        errorReporter = nil
        subject = nil
        super.tearDown()
    }

    // MARK: Tests

    /// Verify that creating an `AuthenticatorBridgeItemData` succeeds and returns the expected modelData
    /// correctly coded.
    ///
    func test_init_success() async throws {
        subject = try AuthenticatorBridgeItemData(
            context: dataStore.persistentContainer.viewContext,
            userId: "userId",
            authenticatorItem: AuthenticatorBridgeItemDataModel(
                bitwardenAccountDomain: "https://vault.example.com",
                bitwardenAccountEmail: "test@example.com",
                favorite: true,
                id: "is",
                name: "name",
                totpKey: "TOTP Key",
                username: "username"
            )
        )

        let modelData = try XCTUnwrap(subject.modelData)
        let model = try JSONDecoder().decode(AuthenticatorBridgeItemDataModel.self, from: modelData)

        XCTAssertEqual(subject.model, model)
    }

    /// Verify that the fetchById request correctly returns an empty list when no item matches the given userId and id.
    ///
    func test_fetchByIdRequest_empty() async throws {
        let expectedItems = AuthenticatorBridgeItemDataView.fixtures()
        try await itemService.insertItems(expectedItems, forUserId: "userId")

        let fetchRequest = AuthenticatorBridgeItemData.fetchByIdRequest(id: "bad id", userId: "userId")
        let result = try dataStore.persistentContainer.viewContext.fetch(fetchRequest)

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 0)
    }

    /// Verify that the fetchById request correctly finds the item with the given userId and id.
    ///
    func test_fetchByIdRequest_success() async throws {
        let expectedItems = AuthenticatorBridgeItemDataView.fixtures()
        let expectedItem = expectedItems[3]
        try await itemService.insertItems(expectedItems, forUserId: "userId")
        XCTAssertTrue(cryptoService.encryptCalled)

        let fetchRequest = AuthenticatorBridgeItemData.fetchByIdRequest(id: expectedItem.id, userId: "userId")
        let result = try dataStore.persistentContainer.viewContext.fetch(fetchRequest)

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 1)

        let decrypted = try await cryptoService.decryptAuthenticatorItems(result.compactMap(\.model))
        let item = try XCTUnwrap(decrypted.first)
        XCTAssertEqual(item, expectedItem)
    }

    /// Verify that the `fetchByUserIdRequest(userId:)` successfully returns an empty list when their are no
    /// items for the given userId
    ///
    func test_fetchByUserIdRequest_empty() async throws {
        let expectedItems = AuthenticatorBridgeItemDataView.fixtures().sorted { $0.id < $1.id }
        try await itemService.insertItems(expectedItems, forUserId: "userId")
        XCTAssertTrue(cryptoService.encryptCalled)

        let fetchRequest = AuthenticatorBridgeItemData.fetchByUserIdRequest(
            userId: "nonexistent userId"
        )
        let result = try dataStore.persistentContainer.viewContext.fetch(fetchRequest)

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, 0)
    }

    /// Verify that the `fetchByUserIdRequest(userId:)` successfully finds all of the data for a given
    /// userId from the store. Verify that it does NOT return any data for a different userId
    ///
    func test_fetchByUserIdRequest_success() async throws {
        // Insert items for "userId"
        let expectedItems = AuthenticatorBridgeItemDataView.fixtures().sorted { $0.id < $1.id }
        try await itemService.insertItems(expectedItems, forUserId: "userId")
        XCTAssertTrue(cryptoService.encryptCalled)

        // Separate Insert for "differentUserId"
        cryptoService.encryptCalled = false
        let differentUserItem = AuthenticatorBridgeItemDataView.fixture()
        try await itemService.insertItems([differentUserItem], forUserId: "differentUserId")
        XCTAssertTrue(cryptoService.encryptCalled)

        // Verify items returned for "userId" do not contain items from "differentUserId"
        let fetchRequest = AuthenticatorBridgeItemData.fetchByUserIdRequest(userId: "userId")
        let result = try dataStore.persistentContainer.viewContext.fetch(fetchRequest)

        XCTAssertNotNil(result)
        XCTAssertEqual(result.count, expectedItems.count)

        // None of the items for userId should contain the item inserted for differentUserId
        let emptyResult = result.filter { $0.id == differentUserItem.id }
        XCTAssertEqual(emptyResult.count, 0)
    }
}
