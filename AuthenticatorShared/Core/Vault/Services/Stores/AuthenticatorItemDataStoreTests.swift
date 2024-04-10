import CoreData
import XCTest

@testable import AuthenticatorShared

class AuthenticatorItemDataStoreTests: AuthenticatorTestCase {
    // MARK: Properties

    var subject: DataStore!

    let authenticatorItems = [
        AuthenticatorItem.fixture(id: "1", name: "item1"),
        AuthenticatorItem.fixture(id: "2", name: "item2"),
        AuthenticatorItem.fixture(id: "3", name: "item3"),
    ]

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        subject = DataStore(errorReporter: MockErrorReporter(), storeType: .memory)
    }

    override func tearDown() {
        super.tearDown()

        subject = nil
    }

    // MARK: Tests

    /// `authenticatorItemPublisher(userId:)` returns a publisher for a user's authenticatorItem objects.
    func test_authenticatorItemPublisher() async throws {
        var publishedValues = [[AuthenticatorItem]]()
        let publisher = subject.authenticatorItemPublisher(userId: "1")
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { values in
                    publishedValues.append(values)
                }
            )
        defer { publisher.cancel() }

        try await subject.replaceAuthenticatorItems(authenticatorItems, userId: "1")

        waitFor { publishedValues.count == 2 }
        XCTAssertTrue(publishedValues[0].isEmpty)
        XCTAssertEqual(publishedValues[1], authenticatorItems)
    }

    /// `deleteAllAuthenticatorItems(user:)` removes all objects for the user.
    func test_deleteAllAuthenticatorItems() async throws {
        try await insertAuthenticatorItems(authenticatorItems, userId: "1")
        try await insertAuthenticatorItems(authenticatorItems, userId: "2")

        try await subject.deleteAllAuthenticatorItems(userId: "1")

        try XCTAssertTrue(fetchAuthenticatorItems(userId: "1").isEmpty)
        try XCTAssertEqual(fetchAuthenticatorItems(userId: "2").count, 3)
    }

    /// `deleteAuthenticatorItem(id:userId:)` removes the authenticatorItem with the given ID for the user.
    func test_deleteAuthenticatorItem() async throws {
        try await insertAuthenticatorItems(authenticatorItems, userId: "1")

        try await subject.deleteAuthenticatorItem(id: "2", userId: "1")

        try XCTAssertEqual(
            fetchAuthenticatorItems(userId: "1"),
            authenticatorItems.filter { $0.id != "2" }
        )
    }

    /// `fetchAuthenticatorItem(withId:)` returns the specified authenticatorItem if it exists and `nil` otherwise.
    func test_fetchAuthenticatorItem() async throws {
        try await insertAuthenticatorItems(authenticatorItems, userId: "1")

        let authenticatorItem1 = try await subject.fetchAuthenticatorItem(withId: "1", userId: "1")
        XCTAssertEqual(authenticatorItem1, authenticatorItems.first)

        let authenticatorItem42 = try await subject.fetchAuthenticatorItem(withId: "42", userId: "1")
        XCTAssertNil(authenticatorItem42)
    }

    /// `replaceAuthenticatorItems(_:userId)` replaces the list of authenticatorItems for the user.
    func test_replaceAuthenticatorItems() async throws {
        try await insertAuthenticatorItems(authenticatorItems, userId: "1")

        let newAuthenticatorItems = [
            AuthenticatorItem.fixture(id: "3", name: "item3"),
            AuthenticatorItem.fixture(id: "4", name: "item4"),
            AuthenticatorItem.fixture(id: "5", name: "item5"),
        ]
        try await subject.replaceAuthenticatorItems(newAuthenticatorItems, userId: "1")

        XCTAssertEqual(try fetchAuthenticatorItems(userId: "1"), newAuthenticatorItems)
    }

    /// `upsertAuthenticatorItem(_:userId:)` inserts a authenticatorItem for a user.
    func test_upsertAuthenticatorItem_insert() async throws {
        let authenticatorItem = AuthenticatorItem.fixture(id: "1")
        try await subject.upsertAuthenticatorItem(authenticatorItem, userId: "1")

        try XCTAssertEqual(fetchAuthenticatorItems(userId: "1"), [authenticatorItem])

        let authenticatorItem2 = AuthenticatorItem.fixture(id: "2")
        try await subject.upsertAuthenticatorItem(authenticatorItem2, userId: "1")

        try XCTAssertEqual(fetchAuthenticatorItems(userId: "1"), [authenticatorItem, authenticatorItem2])
    }

    /// `upsertAuthenticatorItem(_:userId:)` updates an existing authenticatorItem for a user.
    func test_upsertAuthenticatorItem_update() async throws {
        try await insertAuthenticatorItems(authenticatorItems, userId: "1")

        let updatedAuthenticatorItem = AuthenticatorItem.fixture(id: "2", name: "UPDATED CIPHER2")
        try await subject.upsertAuthenticatorItem(updatedAuthenticatorItem, userId: "1")

        var expectedAuthenticatorItems = authenticatorItems
        expectedAuthenticatorItems[1] = updatedAuthenticatorItem

        try XCTAssertEqual(fetchAuthenticatorItems(userId: "1"), expectedAuthenticatorItems)
    }

    // MARK: Test Helpers

    /// A test helper to fetch all authenticatorItem's for a user.
    private func fetchAuthenticatorItems(userId: String) throws -> [AuthenticatorItem] {
        let fetchRequest = AuthenticatorItemData.fetchByUserIdRequest(userId: userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \AuthenticatorItemData.id, ascending: true)]
        return try subject.backgroundContext.fetch(fetchRequest).map(AuthenticatorItem.init)
    }

    /// A test helper for inserting a list of authenticatorItems for a user.
    private func insertAuthenticatorItems(_ authenticatorItems: [AuthenticatorItem], userId: String) async throws {
        try await subject.backgroundContext.performAndSave {
            for authenticatorItem in authenticatorItems {
                _ = try AuthenticatorItemData(
                    context: self.subject.backgroundContext,
                    userId: userId,
                    authenticatorItem: authenticatorItem
                )
            }
        }
    }
}
