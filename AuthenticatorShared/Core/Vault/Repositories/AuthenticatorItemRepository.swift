import AuthenticatorBridgeKit
import BitwardenKit
import BitwardenResources
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
    /// - Returns: An array of all items in storage
    ///
    func fetchAllAuthenticatorItems() async throws -> [AuthenticatorItemView]

    /// Determine if the `enablePasswordManagerSync` feature flag is enabled *and* the user
    /// has turned sync on for at least one account in the BWPM app. If one or both of these is
    /// not `true`, this returns `false`.
    ///
    /// - Returns: `true` if the sync feature flag is enabled and the user has actively synced an account.
    ///     `false` otherwise.
    ///
    func isPasswordManagerSyncActive() async -> Bool

    /// Regenerates the TOTP codes for a list of items.
    ///
    /// - Parameters:
    ///   - items: The list of items that need updated TOTP codes.
    /// - Returns: A list of items with updated TOTP codes.
    ///
    func refreshTotpCodes(on items: [ItemListItem]) async throws -> [ItemListItem]

    /// Create a temporary shared item based on a `AuthenticatorItemView` for sharing with the BWPM app.
    /// This method will store it as a temporary item in the shared store.
    ///
    /// - Parameter item: The item to be shared with the BWPM app
    ///
    func saveTemporarySharedItem(_ item: AuthenticatorItemView) async throws

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

    /// Service to interface with the application.
    private let application: Application

    /// Service from which to fetch locally stored Authenticator items.
    private let authenticatorItemService: AuthenticatorItemService

    /// Service to determine if the sync feature flag is turned on.
    private let configService: ConfigService

    /// Service to encrypt/decrypt locally stored Authenticator items.
    private let cryptographyService: CryptographyService

    /// Error Reporter for any errors encountered
    private let errorReporter: ErrorReporter

    /// Service to fetch items from the shared CoreData store - shared from the main Bitwarden PM app.
    private let sharedItemService: AuthenticatorBridgeItemService

    /// Flag to indicate if there was an error with the data synced from the BWPM app.
    private var syncError = false

    /// A protocol wrapping the present time.
    private let timeProvider: TimeProvider

    /// A service for refreshing TOTP codes.
    private let totpService: TOTPService

    // MARK: Initialization

    /// Initialize a `DefaultAuthenticatorItemRepository`
    ///
    /// - Parameters:
    ///   - application: Service to interact with the application.
    ///   - authenticatorItemService: Service to from which to fetch locally stored Authenticator items.
    ///   - configService: Service to determine if the sync feature flag is turned on.
    ///   - cryptographyService: Service to encrypt/decrypt locally stored Authenticator items.
    ///   - sharedItemService: Service to fetch items from the shared CoreData store - shared from
    ///     the main Bitwarden PM app.
    ///   - errorReporter: Error Reporter for any errors encountered
    ///   - timeProvider: A protocol wrapping the present time.
    ///   - totpService: A service for refreshing TOTP codes.
    init(
        application: Application,
        authenticatorItemService: AuthenticatorItemService,
        configService: ConfigService,
        cryptographyService: CryptographyService,
        errorReporter: ErrorReporter,
        sharedItemService: AuthenticatorBridgeItemService,
        timeProvider: TimeProvider,
        totpService: TOTPService
    ) {
        self.application = application
        self.authenticatorItemService = authenticatorItemService
        self.configService = configService
        self.cryptographyService = cryptographyService
        self.errorReporter = errorReporter
        self.timeProvider = timeProvider
        self.totpService = totpService
        self.sharedItemService = sharedItemService
    }

    // MARK: Private Methods

    /// Combine sections that are locally stored with the list of the sections created with the shared items,
    /// when sync with the BWPM app is enabled.
    ///
    /// Note: If the `enablePasswordManagerSync` feature flag is not enabled, or if the user has not yet
    /// turned on sync for any accounts, this method simply returns `localSections`.
    ///
    /// - Parameters:
    ///   - localSections: The [ItemListSection] sections for the items locally stored
    ///   - sharedItems: The shared items that are coming in via sync with the BWPM app
    /// - Returns: A list of the sections to display in the item list
    ///
    private func combinedSections(
        localSections: [ItemListSection],
        sharedItems: [AuthenticatorBridgeItemDataView]
    ) async -> [ItemListSection] {
        guard await isPasswordManagerSyncActive() else {
            return localSections
        }
        guard !syncError else {
            var sections = localSections
            sections.append(ItemListSection(
                id: "SyncError",
                items: [.syncError()],
                name: ""
            ))
            return sections
        }

        let groupedByAccount = Dictionary(
            grouping: sharedItems,
            by: { item in
                [item.accountEmail, item.accountDomain]
                    .compactMap { $0?.nilIfEmpty }
                    .joined(separator: " | ")
            }
        )

        var sections = localSections

        for key in groupedByAccount.keys.sorted() {
            let items = groupedByAccount[key]?.compactMap { item in
                ItemListItem(itemView: item, timeProvider: self.timeProvider)
            }
            guard let items, !items.isEmpty else {
                continue
            }
            sections.append(ItemListSection(id: key, items: items, name: key))
        }

        return sections
    }

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

        let favorites = items.filter(\.favorite).compactMap { item in
            ItemListItem(authenticatorItemView: item, timeProvider: self.timeProvider)
        }
        let nonFavorites = items.filter { !$0.favorite }.compactMap { item in
            ItemListItem(authenticatorItemView: item, timeProvider: self.timeProvider)
        }

        let useSyncValues = await isPasswordManagerSyncActive()

        return [
            ItemListSection(id: "Favorites", items: favorites, name: Localizations.favorites),
            ItemListSection(id: useSyncValues ? "LocalCodes" : "Unorganized",
                            items: nonFavorites,
                            name: useSyncValues ? Localizations.localCodes : ""),
        ]
        .filter { !$0.items.isEmpty }
    }

    /// Checks to make sure the BWPM app is still installed, as that is required for having items shared
    /// between the apps. If BWPM is found to be uninstalled, then this calls the shared item service to
    /// purge all data in the shared storage.
    ///
    private func checkBWPMInstall() async throws {
        guard await isPasswordManagerSyncActive(),
              !(application.canOpenURL(ExternalLinksConstants.passwordManagerScheme)) else {
            return
        }

        try await sharedItemService.deleteAll()
    }

    /// A Publisher that combines all of the locally stored code with the codes shared from the Bitwarden PM app. This
    /// publisher converts all of these into `[ItemListSection]` ready to be displayed in the ItemList.
    ///
    /// - Returns: An array of `ItemListSection` containing both locally stored and shared codes.
    ///
    private func itemListSectionPublisher() async throws -> AnyPublisher<[ItemListSection], Error> {
        try await checkBWPMInstall()
        let remoteItemsPublisher: any Publisher<[AuthenticatorBridgeItemDataView], any Error>
        do {
            remoteItemsPublisher = try await sharedItemService.sharedItemsPublisher()
                .catch { error -> AnyPublisher<[AuthenticatorBridgeItemDataView], any Error> in
                    self.syncError = true
                    self.errorReporter.log(error: error)

                    return Just([])
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
        } catch {
            syncError = true
            errorReporter.log(error: error)
            remoteItemsPublisher = Just([])
                .setFailureType(to: Error.self)
        }
        return try await authenticatorItemService.authenticatorItemsPublisher()
            .combineLatest(remoteItemsPublisher.eraseToAnyPublisher())
            .asyncTryMap { localItems, sharedItems in
                let sections = try await self.itemListSections(from: localItems)
                return await self.combinedSections(localSections: sections, sharedItems: sharedItems)
            }
            .eraseToAnyPublisher()
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
    }

    func fetchAuthenticatorItem(withId id: String) async throws -> AuthenticatorItemView? {
        guard let item = try await authenticatorItemService.fetchAuthenticatorItem(withId: id) else { return nil }
        return try? await cryptographyService.decrypt(item)
    }

    func isPasswordManagerSyncActive() async -> Bool {
        await sharedItemService.isSyncOn()
    }

    func refreshTotpCodes(on items: [ItemListItem]) async throws -> [ItemListItem] {
        try await items.asyncMap { item in
            let keyModel: TOTPKeyModel?
            switch item.itemType {
            case let .sharedTotp(model):
                let key = model.itemView.totpKey
                keyModel = TOTPKeyModel(authenticatorKey: key)
            case .syncError:
                keyModel = nil // Should be filtered out, no need to refresh codes
            case let .totp(model):
                let key = model.itemView.totpKey
                keyModel = TOTPKeyModel(authenticatorKey: key)
            }
            guard let keyModel else {
                if item.itemType != .syncError {
                    errorReporter.log(error: TOTPServiceError
                        .unableToGenerateCode("Unable to refresh TOTP code for list view item: \(item.id)"))
                }
                return item
            }
            let code = try await totpService.getTotpCode(for: keyModel)
            return item.with(newTotpModel: code)
        }
    }

    func saveTemporarySharedItem(_ item: AuthenticatorItemView) async throws {
        try await sharedItemService.insertTemporaryItem(AuthenticatorBridgeItemDataView(
            accountDomain: nil,
            accountEmail: nil,
            favorite: false,
            id: item.id,
            name: item.name,
            totpKey: item.totpKey,
            username: item.username
        ))
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
        try await itemListSectionPublisher().values
    }

    func searchItemListPublisher(
        searchText: String
    ) async throws -> AsyncThrowingPublisher<AnyPublisher<[ItemListItem], Error>> {
        try await itemListSectionPublisher().map { sections -> [ItemListItem] in
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)

            return sections.flatMap(\.items)
                .filter { item in
                    item.name.lowercased()
                        .folding(options: .diacriticInsensitive, locale: nil)
                        .contains(query)
                }
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }
        .eraseToAnyPublisher()
        .values
    }
} // swiftlint:disable:this file_length
