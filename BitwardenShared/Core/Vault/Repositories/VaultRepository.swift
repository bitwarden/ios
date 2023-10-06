import BitwardenSdk
import Combine
import Foundation

/// A protocol for a `VaultRepository` which manages access to the data needed by the UI layer.
///
protocol VaultRepository: AnyObject {
    // MARK: API Methods

    /// Performs an API request to sync the user's vault data. The publishers in the repository can
    /// be used to subscribe to the vault data, which are updated as a result of the request.
    ///
    func fetchSync() async throws

    // MARK: Publishers

    /// A publisher for the details of a cipher in the vault.
    ///
    /// - Parameter id: The cipher identifier to be notified when the cipher is updated.
    /// - Returns: A publisher for the details of a cipher which will be notified as the details of
    ///     the cipher change.
    ///
    func cipherDetailsPublisher(id: String) -> AsyncPublisher<AnyPublisher<CipherDetailsResponseModel, Never>>

    /// A publisher for the vault list which returns a list of sections and items that are
    /// displayed in the vault.
    ///
    /// - Returns: A publisher for the sections of the vault list which will be notified as the
    ///     data changes.
    ///
    func vaultListPublisher() -> AsyncPublisher<AnyPublisher<[VaultListSection], Never>>

    /// A publisher for a group of items within the vault list.
    ///
    /// - Parameter group: The group of items within the vault list to subscribe to.
    /// - Returns: A publisher for a group of items within the vault list which will be notified as
    ///     the data changes.
    ///
    func vaultListPublisher(group: VaultListGroup) -> AsyncPublisher<AnyPublisher<[VaultListItem], Never>>
}

/// A default implementation of a `VaultRepository`.
///
class DefaultVaultRepository {
    // MARK: Properties

    /// The API service used to perform sync API requests.
    let syncAPIService: SyncAPIService

    /// A subject containing the sync response
    var syncResponseSubject = CurrentValueSubject<SyncResponseModel?, Never>(nil)

    // MARK: Initialization

    /// Initialize a `DefaultVaultRepository`.
    ///
    /// - Parameter syncAPIService: The API service used to perform sync API requests.
    ///
    init(syncAPIService: SyncAPIService) {
        self.syncAPIService = syncAPIService
    }

    // MARK: Private

    /// Returns a list of items that are grouped together in the vault list from a sync response.
    ///
    /// - Parameters:
    ///   - group: The group of items to get.
    ///   - response: The sync response used to build the list of items.
    /// - Returns: A list of items for the group in the vault list.
    ///
    private func vaultListItems(group: VaultListGroup, from response: SyncResponseModel) -> [VaultListItem] {
        let ciphers = response.ciphers
            .filter { $0.deletedDate == nil }
            .sorted { ($0.name ?? "") < ($1.name ?? "") }

        switch group {
        case .login:
            return ciphers.filter { $0.type == .login }.map(VaultListItem.init)
        case .card:
            return ciphers.filter { $0.type == .card }.map(VaultListItem.init)
        case .identity:
            return ciphers.filter { $0.type == .identity }.map(VaultListItem.init)
        case .secureNote:
            return ciphers.filter { $0.type == .secureNote }.map(VaultListItem.init)
        case let .folder(folder):
            return ciphers.filter { $0.folderId == folder.id }.map(VaultListItem.init)
        case .trash:
            return response.ciphers.filter { $0.deletedDate == nil }.map(VaultListItem.init)
        }
    }

    /// Returns a list of the sections in the vault list from a sync response.
    ///
    /// - Parameter response: The sync response used to build the list of sections.
    /// - Returns: A list of the sections to display in the vault list.
    ///
    private func vaultListSections(from response: SyncResponseModel) -> [VaultListSection] {
        let ciphers = response.ciphers
            .filter { $0.deletedDate == nil }
            .sorted { ($0.name ?? "") < ($1.name ?? "") }

        let ciphersFavorites = ciphers.filter(\.favorite).map(VaultListItem.init)
        let ciphersNoFolder = ciphers.filter { $0.folderId == nil }.map(VaultListItem.init)

        let ciphersTrashCount = response.ciphers.lazy.filter { $0.deletedDate != nil }.count
        let ciphersTrashItem = VaultListItem(id: "Trash", itemType: .group(.trash, ciphersTrashCount))

        let folders = response.folders.map { folder in
            let cipherCount = ciphers.lazy.filter { $0.folderId == folder.id }.count
            return VaultListItem(id: folder.id, itemType: .group(.folder(folder), cipherCount))
        }

        let typesCardCount = ciphers.lazy.filter { $0.card != nil }.count
        let typesIdentityCount = ciphers.lazy.filter { $0.identity != nil }.count
        let typesLoginCount = ciphers.lazy.filter { $0.login != nil }.count
        let typesSecureNoteCount = ciphers.lazy.filter { $0.secureNote != nil }.count

        let types = [
            VaultListItem(id: "Types.Logins", itemType: .group(.login, typesLoginCount)),
            VaultListItem(id: "Types.Cards", itemType: .group(.card, typesCardCount)),
            VaultListItem(id: "Types.Identities", itemType: .group(.identity, typesIdentityCount)),
            VaultListItem(id: "Types.SecureNotes", itemType: .group(.secureNote, typesSecureNoteCount)),
        ]

        return [
            VaultListSection(id: "Favorites", items: ciphersFavorites, name: Localizations.favorites),
            VaultListSection(id: "Types", items: types, name: Localizations.types),
            VaultListSection(id: "Folders", items: folders, name: Localizations.folders),
            VaultListSection(id: "NoFolder", items: ciphersNoFolder, name: Localizations.folderNone),
            VaultListSection(id: "Trash", items: [ciphersTrashItem], name: Localizations.trash),
        ]
    }
}

extension DefaultVaultRepository: VaultRepository {
    // MARK: API Methods

    func fetchSync() async throws {
        let response = try await syncAPIService.getSync()
        syncResponseSubject.value = response
    }

    // MARK: Publishers

    func vaultListPublisher() -> AsyncPublisher<AnyPublisher<[VaultListSection], Never>> {
        syncResponseSubject
            .compactMap { response in
                guard let response else { return nil }
                return self.vaultListSections(from: response)
            }
            .eraseToAnyPublisher()
            .values
    }

    func vaultListPublisher(group: VaultListGroup) -> AsyncPublisher<AnyPublisher<[VaultListItem], Never>> {
        syncResponseSubject
            .compactMap { response in
                guard let response else { return nil }
                return self.vaultListItems(group: group, from: response)
            }
            .eraseToAnyPublisher()
            .values
    }

    func cipherDetailsPublisher(id: String) -> AsyncPublisher<AnyPublisher<CipherDetailsResponseModel, Never>> {
        syncResponseSubject
            .compactMap { $0?.ciphers.first(where: { $0.id == id }) }
            .eraseToAnyPublisher()
            .values
    }
}
