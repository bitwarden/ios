import AuthenticatorBridgeKit
import InlineSnapshotTesting
import XCTest

@testable import AuthenticatorShared

class AuthenticatorItemRepositoryTests: AuthenticatorTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var authItemService: MockAuthenticatorItemService!
    var authenticatorItemService: MockAuthenticatorItemService!
    var configService: MockConfigService!
    var cryptographyService: MockCryptographyService!
    var errorReporter: MockErrorReporter!
    var sharedItemService: MockAuthenticatorBridgeItemService!
    var subject: DefaultAuthenticatorItemRepository!
    var timeProvider: MockTimeProvider!
    var totpService: MockTOTPService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        authItemService = MockAuthenticatorItemService()
        authenticatorItemService = MockAuthenticatorItemService()
        configService = MockConfigService()
        cryptographyService = MockCryptographyService()
        errorReporter = MockErrorReporter()
        sharedItemService = MockAuthenticatorBridgeItemService()
        timeProvider = MockTimeProvider(.mockTime(Date()))
        totpService = MockTOTPService()

        subject = DefaultAuthenticatorItemRepository(
            authenticatorItemService: authItemService,
            configService: configService,
            cryptographyService: cryptographyService,
            errorReporter: errorReporter,
            sharedItemService: sharedItemService,
            timeProvider: timeProvider,
            totpService: totpService
        )
    }

    override func tearDown() {
        super.tearDown()

        authItemService = nil
        authenticatorItemService = nil
        cryptographyService = nil
        sharedItemService = nil
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

    /// `refreshTotpCodes(on:)` logs an error when it can't update the TOTP code on a
    /// .sharedTotp item, and returns the item as-is.
    func test_refreshTotpCodes_errorSharedTotp() async throws {
        let item = ItemListItem.fixtureShared(totp: .fixture(itemView: .fixture(totpKey: nil)))

        let result = try await subject.refreshTotpCodes(on: [item])
        let actual = try XCTUnwrap(result[0])
        let error = try XCTUnwrap(errorReporter.errors[0] as? TOTPServiceError)
        XCTAssertEqual(
            error,
            .unableToGenerateCode("Unable to refresh TOTP code for list view item: \(item.id)")
        )
        XCTAssertEqual(actual.id, item.id)
        XCTAssertEqual(actual.name, item.name)
        XCTAssertEqual(actual.accountName, item.accountName)
    }

    /// `refreshTotpCodes(on:)` logs an error when it can't update the TOTP code on a
    /// .totp item, and returns the item as-is.
    func test_refreshTotpCodes_errorTotp() async throws {
        let item = ItemListItem.fixture(totp: .fixture(itemView: .fixture(totpKey: nil)))

        let result = try await subject.refreshTotpCodes(on: [item])
        let actual = try XCTUnwrap(result[0])
        let error = try XCTUnwrap(errorReporter.errors[0] as? TOTPServiceError)
        XCTAssertEqual(
            error,
            .unableToGenerateCode("Unable to refresh TOTP code for list view item: \(item.id)")
        )
        XCTAssertEqual(actual.id, item.id)
        XCTAssertEqual(actual.name, item.name)
        XCTAssertEqual(actual.accountName, item.accountName)
    }

    /// `refreshTotpCodes(on:)` updates the TOTP codes on items.
    func test_refreshTotpCodes_success() async throws {
        let newCode = "987654"
        let newCodeModel = TOTPCodeModel(
            code: newCode,
            codeGenerationDate: timeProvider.presentTime,
            period: 30
        )
        totpService.getTotpCodeResult = .success(newCodeModel)

        let item = ItemListItem.fixture()
        let sharedItem = ItemListItem.fixtureShared()

        let result = try await subject.refreshTotpCodes(on: [item, sharedItem])
        let actual = try XCTUnwrap(result[0])

        XCTAssertEqual(actual.id, item.id)
        XCTAssertEqual(actual.name, item.name)
        XCTAssertEqual(actual.accountName, item.accountName)
        switch actual.itemType {
        case .sharedTotp:
            XCTFail("Shared TOTP itemType found when expecting TOTP")
        case let .totp(model):
            XCTAssertEqual(model.totpCode, newCodeModel)
        }

        let shared = try XCTUnwrap(result[1])

        XCTAssertEqual(shared.id, sharedItem.id)
        XCTAssertEqual(shared.name, sharedItem.name)
        XCTAssertEqual(shared.accountName, sharedItem.accountName)
        switch shared.itemType {
        case let .sharedTotp(model):
            XCTAssertEqual(model.totpCode, newCodeModel)
        case .totp:
            XCTFail("TOTP itemType found when expecting Shared TOTP")
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
        configService.featureFlagsBool[.enablePasswordManagerSync] = false
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

    /// `itemListPublisher()` returns a favorites section (when the feature flag not enabled)
    func test_itemListPublisher_favorites() async throws {
        sharedItemService.storedItems = ["userId": AuthenticatorBridgeItemDataView.fixtures()]
        sharedItemService.syncOn = true
        configService.featureFlagsBool[.enablePasswordManagerSync] = false
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

    /// `itemListPublisher()` returns a favorites section as before, when the feature flag is enabled, but
    /// the user has not yet enabled sync.
    func test_itemListPublisher_syncOff() async throws {
        configService.featureFlagsBool[.enablePasswordManagerSync] = true
        sharedItemService.storedItems = ["userId": AuthenticatorBridgeItemDataView.fixtures()]
        sharedItemService.syncOn = false
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

    /// `itemListPublisher()` returns a favorites section and sections for each sync'd account when the
    /// feature flag is enabled and the user has turned on sync.
    func test_itemListPublisher_syncOn() async throws {
        configService.featureFlagsBool[.enablePasswordManagerSync] = true
        sharedItemService.syncOn = true
        let items = [
            AuthenticatorItem.fixture(id: "1", name: "One"),
            AuthenticatorItem.fixture(favorite: true, id: "2", name: "Two"),
        ]
        let sharedItem = AuthenticatorBridgeItemDataView.fixture(accountDomain: "Domain",
                                                                 accountEmail: "shared@example.com",
                                                                 totpKey: "totpKey")
        sharedItemService.storedItems = ["userId": [sharedItem]]
        let unorganizedItem = itemListItem(from: items[0])
        let favoritedItem = itemListItem(from: items[1])
        let sharedListItem = itemListItem(from: sharedItem)

        authItemService.authenticatorItemsSubject.send(items)
        sharedItemService.sharedItemsSubject.send([
            sharedItem,
        ])

        var iterator = try await subject.itemListPublisher().makeAsyncIterator()
        let sections = try await iterator.next()

        XCTAssertEqual(
            sections,
            [
                ItemListSection(id: "Favorites",
                                items: [favoritedItem],
                                name: Localizations.favorites),
                ItemListSection(id: "LocalCodes",
                                items: [unorganizedItem],
                                name: Localizations.localCodes),
                ItemListSection(id: "shared@example.com | Domain",
                                items: [sharedListItem],
                                name: "shared@example.com | Domain"),
            ]
        )
    }

    /// `itemListPublisher()` correctly handles the empty/nil cases for different sections of the item list when
    /// the feature flag is enabled and the user has turned on Sync for multiple accounts..
    func test_itemListPublisher_withMultipleAccountSync() async throws {
        configService.featureFlagsBool[.enablePasswordManagerSync] = true
        sharedItemService.syncOn = true
        let fullItem = AuthenticatorBridgeItemDataView.fixture(accountDomain: "Domain",
                                                               accountEmail: "shared@example.com",
                                                               name: "Shared",
                                                               totpKey: "totpKey")
        let noDomain = AuthenticatorBridgeItemDataView.fixture(accountEmail: "shared@example.com",
                                                               name: "Shared",
                                                               totpKey: "totpKey")
        let noEmail = AuthenticatorBridgeItemDataView.fixture(accountDomain: "Domain",
                                                              name: "Shared",
                                                              totpKey: "totpKey")
        let neither = AuthenticatorBridgeItemDataView.fixture(name: "Shared",
                                                              totpKey: "totpKey")
        sharedItemService.storedItems = [
            "userId": [fullItem],
            "userId2": [noDomain],
            "userId3": [noEmail],
            "userId4": [neither],
        ]
        let fullListItem = itemListItem(from: fullItem)
        let noDomainItem = itemListItem(from: noDomain)
        let noEmailItem = itemListItem(from: noEmail)
        let neitherItem = itemListItem(from: neither)

        sharedItemService.sharedItemsSubject.send([fullItem, noDomain, noEmail, neither])

        var iterator = try await subject.itemListPublisher().makeAsyncIterator()
        let sections = try await iterator.next()

        XCTAssertEqual(
            sections,
            [
                ItemListSection(id: "",
                                items: [neitherItem],
                                name: ""),
                ItemListSection(id: "Domain",
                                items: [noEmailItem],
                                name: "Domain"),
                ItemListSection(id: "shared@example.com",
                                items: [noDomainItem],
                                name: "shared@example.com"),
                ItemListSection(id: "shared@example.com | Domain",
                                items: [fullListItem],
                                name: "shared@example.com | Domain"),
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

    /// `searchItemListPublisher()` searches case-insensitive and folding diacritics.
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

    // MARK: - Private functions

    /// Convenience method to create an `ItemListItem` from an `AuthenticatorItem` using our test fixtures.
    ///
    /// - Parameter item: The item to convert to `ItemListItem`
    /// - Returns: the `ItemListItem` created with this `AuthenticatorItem`
    ///
    private func itemListItem(from item: AuthenticatorItem) -> ItemListItem {
        ItemListItem.fixture(
            id: item.id,
            name: item.name,
            totp: ItemListTotpItem.fixture(
                itemView: AuthenticatorItemView(authenticatorItem: item),
                totpCode: TOTPCodeModel(
                    code: "123456",
                    codeGenerationDate: timeProvider.presentTime,
                    period: 30
                )
            )
        )
    }

    /// Convenience method to create an `ItemListItem` from
    /// an `AuthenticatorBridgeItemDataView` using our test fixtures.
    ///
    /// - Parameter item: The item to convert to `ItemListItem`
    /// - Returns: the `ItemListItem` created with this `AuthenticatorBridgeItemDataView`
    ///
    private func itemListItem(from item: AuthenticatorBridgeItemDataView) -> ItemListItem {
        ItemListItem.fixtureShared(
            id: item.id,
            name: item.name,
            accountName: item.username,
            totp: ItemListSharedTotpItem.fixture(
                itemView: item,
                totpCode: TOTPCodeModel(
                    code: "123456",
                    codeGenerationDate: timeProvider.presentTime,
                    period: 30
                )
            )
        )
    }
} // swiftlint:disable:this file_length
