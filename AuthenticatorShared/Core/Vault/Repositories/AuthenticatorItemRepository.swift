import Combine
import Foundation

// MARK: - AuthenticatorItemRepository

/// A protocol for an `AuthenticatorItemRepository` which manages access to the data layer for items
///
protocol AuthenticatorItemRepository: AnyObject {
    // MARK: Data Methods

    /// Adds an item to the user's storage
    ///
    /// - Parameters:
    ///   - authenticatorItem: The item to add
    ///
    func addAuthenticatorItem(_ authenticatorItem: AuthenticatorItemView) async throws

    /// Deletes an item from the user's storage
    ///
    /// - Parameters:
    ///   - id: The item ID to delete
    ///
    func deleteAuthenticatorItem(_ id: String) async throws

    /// Attempt to fetch an item with the given ID
    ///
    /// - Parameters:
    ///   - id: The ID of the item to find
    /// - Returns: The item if found and `nil` if not
    ///
    func fetchAuthenticatorItem(withId id: String) async throws -> AuthenticatorItemView?

    /// Fetch all items
    ///
    /// Returns: An array of all items in storage
    ///
    func fetchAllAuthenticatorItems() async throws -> [AuthenticatorItemView]

    /// Updates an item in the user's storage
    ///
    /// - Parameters:
    ///   - authenticatorItem: The updated item
    ///
    func updateAuthenticatorItem(_ authenticatorItem: AuthenticatorItemView) async throws

    // MARK: Publishers

    /// A publisher for the details of an item
    ///
    /// - Parameters:
    ///   - id: The ID of the item that should be published
    /// - Returns: A publisher for the details of the item,
    ///            which will be notified as details of the item change
    ///
    func authenticatorItemDetailsPublisher(
        id: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<AuthenticatorItemView?, Error>>

    /// A publisher for the list of a user's items, which returns a list of sections
    /// of items that are displayed
    ///
    /// - Returns: A publisher for the list of a user's items
    ///
    func itemListPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[ItemListSection], Error>>

    /// A publisher for searching a user's cipher objects based on the specified search text and filter type.
    ///
    /// - Parameters:
    ///   - searchText: The search text to filter the cipher list.
    /// - Returns: A publisher searching for the user's ciphers.
    ///
    func searchItemListPublisher(
        searchText: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[ItemListItem], Error>>
}

// MARK: - DefaultAuthenticatorItemRepository

/// A default implementation of an `AuthenticatorItemRepository`
///
class DefaultAuthenticatorItemRepository {
    // MARK: Properties

    private let authenticatorItemService: AuthenticatorItemService
    private let cryptographyService: CryptographyService

    // MARK: Initialization

    /// Initialize a `DefaultAuthenticatorItemRepository`
    ///
    /// - Parameters:
    ///   - authenticatorItemService
    ///   - cryptographyService
    init(
        authenticatorItemService: AuthenticatorItemService,
        cryptographyService: CryptographyService
    ) {
        self.authenticatorItemService = authenticatorItemService
        self.cryptographyService = cryptographyService
    }

    // MARK: Private Methods

    /// Returns a list of the sections in the item list
    ///
    /// - Parameters:
    ///   - authenticatorItems: The items in the user's storage
    /// - Returns: A list of the sections to display in the item list
    ///
    private func itemListSections(
        from authenticatorItems: [AuthenticatorItem]
    ) async throws -> [ItemListSection] {
        let items = try await authenticatorItems.asyncMap { item in
            try await self.cryptographyService.decrypt(item)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let favorites = items.filter(\.favorite).compactMap(ItemListItem.init)
        let nonFavorites = items.filter { !$0.favorite }.compactMap(ItemListItem.init)

        return [
            ItemListSection(id: "Favorites", items: favorites, name: Localizations.favorites),
            ItemListSection(id: "Unorganized", items: nonFavorites, name: ""),
        ]
        .filter { !$0.items.isEmpty }
    }

    /// A publisher for searching a user's items based on the specified search text and filter type.
    ///
    /// - Parameters:
    ///   - searchText: The search text to filter the item list.
    /// - Returns: A publisher searching for the user's ciphers.
    ///
    private func searchPublisher(
        searchText: String
    ) async throws -> AnyPublisher<[AuthenticatorItemView], Error> {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        return try await authenticatorItemService.authenticatorItemsPublisher()
            .asyncTryMap { items -> [AuthenticatorItemView] in
                let matchingItems = try await items.asyncMap { item in
                    try await self.cryptographyService.decrypt(item)
                }

                var matchedItems: [AuthenticatorItemView] = []

                matchingItems.forEach { item in
                    if item.name.lowercased()
                        .folding(options: .diacriticInsensitive, locale: nil)
                        .contains(query) {
                        matchedItems.append(item)
                    }
                }

                return matchedItems.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            }.eraseToAnyPublisher()
    }
}

extension DefaultAuthenticatorItemRepository: AuthenticatorItemRepository {
    // MARK: Data Methods

    func addAuthenticatorItem(_ authenticatorItem: AuthenticatorItemView) async throws {
        let item = try await cryptographyService.encrypt(authenticatorItem)
        try await authenticatorItemService.addAuthenticatorItem(item)
    }

    func deleteAuthenticatorItem(_ id: String) async throws {
        try await authenticatorItemService.deleteAuthenticatorItem(id: id)
    }

    func fetchAllAuthenticatorItems() async throws -> [AuthenticatorItemView] {
        let items = try await authenticatorItemService.fetchAllAuthenticatorItems()
        return try await items.asyncMap { item in
            try await cryptographyService.decrypt(item)
        }
        .compactMap { $0 }
    }

    func fetchAuthenticatorItem(withId id: String) async throws -> AuthenticatorItemView? {
        guard let item = try await authenticatorItemService.fetchAuthenticatorItem(withId: id) else { return nil }
        return try? await cryptographyService.decrypt(item)
    }

    func updateAuthenticatorItem(_ authenticatorItem: AuthenticatorItemView) async throws {
        let item = try await cryptographyService.encrypt(authenticatorItem)
        try await authenticatorItemService.updateAuthenticatorItem(item)
    }

    // MARK: Publishers

    func authenticatorItemDetailsPublisher(
        id: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<AuthenticatorItemView?, Error>> {
        try await authenticatorItemService.authenticatorItemsPublisher()
            .asyncTryMap { items -> AuthenticatorItemView? in
                guard let item = items.first(where: { $0.id == id }) else { return nil }
                return try await self.cryptographyService.decrypt(item)
            }
            .eraseToAnyPublisher()
            .values
    }

    func itemListPublisher() async throws -> AsyncThrowingPublisher<AnyPublisher<[ItemListSection], Error>> {
        try await authenticatorItemService.authenticatorItemsPublisher()
            .asyncTryMap { items in
                try await self.itemListSections(from: items)
            }
            .eraseToAnyPublisher()
            .values
    }

    func searchItemListPublisher(
        searchText: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[ItemListItem], Error>> {
        try await searchPublisher(
            searchText: searchText
        ).asyncTryMap { items in
            items.compactMap(ItemListItem.init)
        }
        .eraseToAnyPublisher()
        .values
    }
}
