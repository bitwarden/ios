import XCTest

@testable import AuthenticatorShared

class AuthenticatorItemServiceTests: AuthenticatorTestCase {
    // MARK: Properties

    var authenticatorItemDataStore: MockAuthenticatorItemDataStore!
    var subject: AuthenticatorItemService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authenticatorItemDataStore = MockAuthenticatorItemDataStore()

        subject = DefaultAuthenticatorItemService(
            authenticatorItemDataStore: authenticatorItemDataStore
        )
    }

    override func tearDown() {
        super.tearDown()

        authenticatorItemDataStore = nil
        subject = nil
    }

    // MARK: Tests

    /// `addAuthenticatorItem(_:)` adds the item to local storage
    func test_addAuthenticatorItem() async throws {
        try await subject.addAuthenticatorItem(.fixture())

        XCTAssertEqual(authenticatorItemDataStore.upsertAuthenticatorItemValue?.id, "ID")
    }

    /// `authenticatorItemsPublisher()` returns a publisher that emits data as the data store changes
    func test_authenticatorItemsPublisher() async throws {
        var iterator = try await subject.authenticatorItemsPublisher()
            .values
            .makeAsyncIterator()
        _ = try await iterator.next()

        let item = AuthenticatorItem.fixture()
        authenticatorItemDataStore.authenticatorItemSubject.value = [item]
        let publisherValue = try await iterator.next()
        try XCTAssertEqual(XCTUnwrap(publisherValue), [item])
    }

    /// `deleteAuthenticatorItem(id:)` deletes the item from local storage
    func test_deleteAuthenticatorItem() async throws {
        try await subject.deleteAuthenticatorItem(id: "Test")

        XCTAssertEqual(authenticatorItemDataStore.deleteAuthenticatorItemId, "Test")
        XCTAssertEqual(authenticatorItemDataStore.deleteAuthenticatorItemUserId, "local")
    }

    /// `fetchAuthenticatorItem(withId:)` returns the item if it exists and nil otherwise
    func test_fetchAuthenticatorItem() async throws {
        var item = try await subject.fetchAuthenticatorItem(withId: "1")
        XCTAssertNil(item)
        XCTAssertEqual(authenticatorItemDataStore.fetchAuthenticatorItemId, "1")

        let testItem = AuthenticatorItem.fixture(id: "2")
        authenticatorItemDataStore.fetchAuthenticatorItemResult = testItem

        item = try await subject.fetchAuthenticatorItem(withId: "2")
        XCTAssertEqual(item, testItem)
        XCTAssertEqual(authenticatorItemDataStore.fetchAuthenticatorItemId, "2")
    }

    /// `fetchAllAuthenticatorItems()` returns all items
    func test_fetchAllAuthenticatorItems() async throws {
        authenticatorItemDataStore.fetchAllAuthenticatorItemsResult = .success([
            .fixture(id: "1"),
            .fixture(id: "2"),
        ])

        let items = try await subject.fetchAllAuthenticatorItems()
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].id, "1")
        XCTAssertEqual(items[1].id, "2")
    }

    /// `updateAuthenticatorItemWithLocalStorage(_:)` updates the item in the local storage.
    func test_updateAuthenticatorItemWithLocalStorage() async throws {
        try await subject.updateAuthenticatorItem(.fixture(id: "id"))

        XCTAssertEqual(authenticatorItemDataStore.upsertAuthenticatorItemValue?.id, "id")
    }
}
