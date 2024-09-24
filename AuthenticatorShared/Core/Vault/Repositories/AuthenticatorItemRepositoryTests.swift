import InlineSnapshotTesting
import XCTest

@testable import AuthenticatorShared

class AuthenticatorItemRepositoryTests: AuthenticatorTestCase {
    // MARK: Properties

    var authItemService: MockAuthenticatorItemService!
    var cryptographyService: MockCryptographyService!
    var errorReporter: MockErrorReporter!
    var timeProvider: MockTimeProvider!
    var totpService: MockTOTPService!
    var subject: DefaultAuthenticatorItemRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authItemService = MockAuthenticatorItemService()
        cryptographyService = MockCryptographyService()
        errorReporter = MockErrorReporter()
        timeProvider = MockTimeProvider(.mockTime(Date()))
        totpService = MockTOTPService()

        subject = DefaultAuthenticatorItemRepository(
            authenticatorItemService: authItemService,
            cryptographyService: cryptographyService,
            errorReporter: errorReporter,
            timeProvider: timeProvider,
            totpService: totpService
        )
    }

    override func tearDown() {
        super.tearDown()

        authItemService = nil
        cryptographyService = nil
        subject = nil
        timeProvider = nil
    }

    // MARK: Tests

    /// `addAuthenticatorItem()` updates the items in storage
    func test_addAuthenticatorItem() async throws {
        let item = AuthenticatorItemView.fixture()
        try await subject.addAuthenticatorItem(item)

        XCTAssertEqual(cryptographyService.encryptedAuthenticatorItems, [item])
        XCTAssertEqual(
            authItemService.addAuthenticatorItemAuthenticatorItems.last,
            AuthenticatorItem(authenticatorItemView: item)
        )
    }

    /// `addAuthenticatorItem()` throws an error if encrypting the item fails
    func test_addAuthenticatorItem_encryptError() async {
        cryptographyService.encryptError = AuthenticatorTestError.example

        await assertAsyncThrows(error: AuthenticatorTestError.example) {
            try await subject.addAuthenticatorItem(.fixture())
        }
    }

    /// `deleteAuthenticatorItem()` deletes the item from storage.
    func test_deleteAuthenticatorItem() async throws {
        try await subject.deleteAuthenticatorItem("1")
        XCTAssertEqual(authItemService.deleteAuthenticatorItemId, "1")
    }

    /// `fetchAllAuthenticatorItems()` returns the list of items from storage.
    func test_fetchAllAuthenticatorItems() async throws {
        let items = [
            AuthenticatorItem.fixture(id: "1"),
            AuthenticatorItem.fixture(id: "2"),
            AuthenticatorItem.fixture(id: "3"),
        ]
        let expected = items.map(AuthenticatorItemView.init)
        authItemService.fetchAllAuthenticatorItemsResult = .success(items)

        let result = try await subject.fetchAllAuthenticatorItems()
        XCTAssertEqual(cryptographyService.decryptedAuthenticatorItems, items)
        XCTAssertEqual(result, expected)
    }

    /// `fetchAuthenticatorItem()` returns the item if it exists.
    func test_fetchAuthenticatorItem_exists() async throws {
        let item = AuthenticatorItem.fixture()
        let expected = AuthenticatorItemView(authenticatorItem: .fixture())
        authItemService.fetchAuthenticatorItemResult = .success(item)

        let result = try await subject.fetchAuthenticatorItem(withId: "1")
        XCTAssertEqual(authItemService.fetchAuthenticatorItemId, "1")
        XCTAssertEqual(cryptographyService.decryptedAuthenticatorItems, [item])
        XCTAssertEqual(result, expected)
    }

    /// `fetchAuthenticatorItem()` returns `nil` if the item does not exist.
    func test_fetchAuthenticatorItem_nil() async throws {
        let result = try await subject.fetchAuthenticatorItem(withId: "1")
        XCTAssertEqual(authItemService.fetchAuthenticatorItemId, "1")
        XCTAssertNil(result)
    }

    /// `refreshTotpCodes(on:)` updates the TOTP codes on items.
    func test_refreshTotpCodes() async throws {
        let newCode = "987654"
        let newCodeModel = TOTPCodeModel(
            code: newCode,
            codeGenerationDate: timeProvider.presentTime,
            period: 30
        )
        totpService.getTotpCodeResult = .success(newCodeModel)

        let item = ItemListItem.fixture()

        let result = try await subject.refreshTotpCodes(on: [item])
        let actual = try XCTUnwrap(result[0])

        XCTAssertEqual(actual.id, item.id)
        XCTAssertEqual(actual.name, item.name)
        XCTAssertEqual(actual.accountName, item.accountName)
        switch actual.itemType {
        case let .totp(model):
            XCTAssertEqual(model.totpCode, newCodeModel)
        }
    }

    /// `updateAuthenticatorItem()` updates the item in storage.
    func test_updateAuthenticatorItem() async throws {
        let item = AuthenticatorItemView.fixture()
        let expected = AuthenticatorItem(authenticatorItemView: item)
        try await subject.updateAuthenticatorItem(item)
        XCTAssertEqual(cryptographyService.encryptedAuthenticatorItems, [item])
        XCTAssertEqual(authItemService.updateAuthenticatorItemAuthenticatorItem, expected)
    }

    // MARK: Publishers Tests

    /// `authenticatorItemDetailsPublisher(id:)` returns a publisher for the details of an item.
    func test_authenticatorItemDetailsPublisher() async throws {
        authItemService.authenticatorItemsSubject.send([
            AuthenticatorItem.fixture(id: "1", name: "One"),
        ])

        var iterator = try await subject.authenticatorItemDetailsPublisher(id: "1").makeAsyncIterator()
        let itemDetails = try await iterator.next()

        XCTAssertEqual(itemDetails??.name, "One")
    }

    /// `authenticatorItemDetailsPublisher(id:)` returns nil if the item doesn't exist.
    func test_authenticatorItemDetailsPublisher_nil() async throws {
        authItemService.authenticatorItemsSubject.send([
            AuthenticatorItem.fixture(id: "1", name: "One"),
        ])

        var iterator = try await subject.authenticatorItemDetailsPublisher(id: "2").makeAsyncIterator()
        let itemDetails = try await iterator.next()

        XCTAssertNil(itemDetails as? AuthenticatorItemView)
    }

    /// `itemListPublisher()` returns a publisher for the items.
    func test_itemListPublisher() async throws {
        let items = [
            AuthenticatorItem.fixture(id: "1", name: "One"),
            AuthenticatorItem.fixture(id: "2", name: "Two"),
            AuthenticatorItem.fixture(id: "3", name: "Three"),
        ]
        let codeModel = TOTPCodeModel(
            code: "123456",
            codeGenerationDate: timeProvider.presentTime,
            period: 30
        )
        totpService.getTotpCodeResult = .success(codeModel)
        let expected = items.map { item in
            ItemListItem.fixture(
                id: item.id,
                name: item.name,
                totp: ItemListTotpItem.fixture(
                    itemView: AuthenticatorItemView(authenticatorItem: item),
                    totpCode: codeModel
                )
            )
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        authItemService.authenticatorItemsSubject.send(items)

        var iterator = try await subject.itemListPublisher().makeAsyncIterator()
        let sections = try await iterator.next()

        XCTAssertEqual(
            sections,
            [
                ItemListSection(id: "Unorganized",
                                items: expected,
                                name: ""),
            ]
        )
    }

    /// `itemListPublisher()` returns a favorites section.
    func test_itemListPublisher_favorites() async throws {
        let items = [
            AuthenticatorItem.fixture(id: "1", name: "One"),
            AuthenticatorItem.fixture(favorite: true, id: "2", name: "Two"),
        ]

        let unorganizedItem = ItemListItem.fixture(
            id: items[0].id,
            name: items[0].name,
            totp: ItemListTotpItem.fixture(
                itemView: AuthenticatorItemView(authenticatorItem: items[0]),
                totpCode: TOTPCodeModel(
                    code: "123456",
                    codeGenerationDate: timeProvider.presentTime,
                    period: 30
                )
            )
        )
        let favoritedItem = ItemListItem.fixture(
            id: items[1].id,
            name: items[1].name,
            totp: ItemListTotpItem.fixture(
                itemView: AuthenticatorItemView(authenticatorItem: items[1]),
                totpCode: TOTPCodeModel(
                    code: "123456",
                    codeGenerationDate: timeProvider.presentTime,
                    period: 30
                )
            )
        )

        authItemService.authenticatorItemsSubject.send(items)

        var iterator = try await subject.itemListPublisher().makeAsyncIterator()
        let sections = try await iterator.next()

        XCTAssertEqual(
            sections,
            [
                ItemListSection(id: "Favorites",
                                items: [favoritedItem],
                                name: Localizations.favorites),
                ItemListSection(id: "Unorganized",
                                items: [unorganizedItem],
                                name: ""),
            ]
        )
    }

    /// `searchItemListPublisher()` returns search matching name.
    func test_searchItemListPublisher() async throws {
        let items = [
            AuthenticatorItem.fixture(id: "1", name: "Teahouse"),
            AuthenticatorItem.fixture(id: "2", name: "Restaurant"),
            AuthenticatorItem.fixture(id: "3", name: "Café"),
        ]
        let codeModel = TOTPCodeModel(
            code: "123456",
            codeGenerationDate: timeProvider.presentTime,
            period: 30
        )
        totpService.getTotpCodeResult = .success(codeModel)
        let expected = items.map { item in
            ItemListItem.fixture(
                id: item.id,
                name: item.name,
                totp: ItemListTotpItem.fixture(
                    itemView: AuthenticatorItemView(authenticatorItem: item),
                    totpCode: codeModel
                )
            )
        }

        authItemService.authenticatorItemsSubject.send(items)

        var iterator = try await subject.searchItemListPublisher(searchText: "t").makeAsyncIterator()
        let foundItems = try await iterator.next()

        XCTAssertEqual(foundItems, [expected[1], expected[0]])
    }

    /// `searchItemListPublisher()` searches case-insentivie and folding diacritics.
    func test_searchItemListPublisher_caseAndDiacritics() async throws {
        let items = [
            AuthenticatorItem.fixture(id: "1", name: "Restaurant"),
            AuthenticatorItem.fixture(id: "2", name: "Teahouse"),
            AuthenticatorItem.fixture(id: "3", name: "Café"),
        ]
        let codeModel = TOTPCodeModel(
            code: "123456",
            codeGenerationDate: timeProvider.presentTime,
            period: 30
        )
        totpService.getTotpCodeResult = .success(codeModel)
        let expected = items.map { item in
            ItemListItem.fixture(
                id: item.id,
                name: item.name,
                totp: ItemListTotpItem.fixture(
                    itemView: AuthenticatorItemView(authenticatorItem: item),
                    totpCode: codeModel
                )
            )
        }

        authItemService.authenticatorItemsSubject.send(items)

        var iterator = try await subject.searchItemListPublisher(searchText: "cafe").makeAsyncIterator()
        let foundItems = try await iterator.next()

        XCTAssertEqual(foundItems, [expected.last!])
    }
}
