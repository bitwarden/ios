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

    // MARK: Data Methods

    /// Adds a cipher to the user's vault.
    ///
    /// - Parameter cipher: The cipher that the user is added.
    ///
    func addCipher(_ cipher: CipherView) async throws

    // MARK: Publishers

    /// A publisher for the details of a cipher in the vault.
    ///
    /// - Parameter id: The cipher identifier to be notified when the cipher is updated.
    /// - Returns: A publisher for the details of a cipher which will be notified as the details of
    ///     the cipher change.
    ///
    func cipherDetailsPublisher(id: String) -> AsyncPublisher<AnyPublisher<CipherView, Never>>

    /// Removes an account id.
    ///
    ///  - Parameter userId: An optional userId. Defaults to the active user id.
    ///
    func remove(userId: String?) async

    /// Updates a cipher in the user's vault.
    ///
    /// - Parameter cipher: The cipher that the user is updating.
    ///
    func updateCipher(_ cipher: CipherView) async throws

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

    /// The API service used to perform API requests for the ciphers in a user's vault.
    let cipherAPIService: CipherAPIService

    /// The client used by the application to handle vault encryption and decryption tasks.
    let clientVault: ClientVaultService

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// The API service used to perform sync API requests.
    let syncAPIService: SyncAPIService

    /// The service used by the application to manage vault access.
    let vaultTimeoutService: VaultTimeoutService

    /// A subject containing the sync response.
    var syncResponseSubject = CurrentValueSubject<SyncResponseModel?, Never>(nil)

    // MARK: Initialization

    /// Initialize a `DefaultVaultRepository`.
    ///
    /// - Parameters:
    ///   - cipherAPIService: The API service used to perform API requests for the ciphers in a user's vault.
    ///   - clientVault: The client used by the application to handle vault encryption and decryption tasks.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncAPIService: The API service used to perform sync API requests.
    ///   - vaultTimeoutService: The service used by the application to manage vault access.
    ///
    init(
        cipherAPIService: CipherAPIService,
        clientVault: ClientVaultService,
        stateService: StateService,
        syncAPIService: SyncAPIService,
        vaultTimeoutService: VaultTimeoutService
    ) {
        self.cipherAPIService = cipherAPIService
        self.clientVault = clientVault
        self.stateService = stateService
        self.syncAPIService = syncAPIService
        self.vaultTimeoutService = vaultTimeoutService

        Task {
            for await shouldClearData in vaultTimeoutService.shouldClearDecryptedDataPublisher() {
                guard shouldClearData else { continue }
                syncResponseSubject.value = nil
            }
        }
    }

    // MARK: Private

    /// Returns a list of items that are grouped together in the vault list from a sync response.
    ///
    /// - Parameters:
    ///   - group: The group of items to get.
    ///   - response: The sync response used to build the list of items.
    /// - Returns: A list of items for the group in the vault list.
    ///
    private func vaultListItems(
        group: VaultListGroup,
        from response: SyncResponseModel
    ) async throws -> [VaultListItem] {
        let ciphers = try await clientVault.ciphers()
            .decryptList(ciphers: response.ciphers.map(Cipher.init))
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let activeCiphers = ciphers.filter { $0.deletedDate == nil }
        let deletedCiphers = ciphers.filter { $0.deletedDate != nil }

        switch group {
        case .login:
            return activeCiphers.filter { $0.type == .login }.compactMap(VaultListItem.init)
        case .card:
            return activeCiphers.filter { $0.type == .card }.compactMap(VaultListItem.init)
        case .identity:
            return activeCiphers.filter { $0.type == .identity }.compactMap(VaultListItem.init)
        case .secureNote:
            return activeCiphers.filter { $0.type == .secureNote }.compactMap(VaultListItem.init)
        case let .folder(id, _):
            return activeCiphers.filter { $0.folderId == id }.compactMap(VaultListItem.init)
        case .trash:
            return deletedCiphers.compactMap(VaultListItem.init)
        }
    }

    /// Returns a list of the sections in the vault list from a sync response.
    ///
    /// - Parameter response: The sync response used to build the list of sections.
    /// - Returns: A list of the sections to display in the vault list.
    ///
    private func vaultListSections(from response: SyncResponseModel) async throws -> [VaultListSection] {
        let ciphers = try await clientVault.ciphers()
            .decryptList(ciphers: response.ciphers.map(Cipher.init))
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let folders = try await clientVault.folders()
            .decryptList(folders: response.folders.map(Folder.init))
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let activeCiphers = ciphers.filter { $0.deletedDate == nil }

        let ciphersFavorites = activeCiphers.filter(\.favorite).compactMap(VaultListItem.init)
        let ciphersNoFolder = activeCiphers.filter { $0.folderId == nil }.compactMap(VaultListItem.init)

        let ciphersTrashCount = ciphers.lazy.filter { $0.deletedDate != nil }.count
        let ciphersTrashItem = VaultListItem(id: "Trash", itemType: .group(.trash, ciphersTrashCount))

        let folderItems = folders.map { folder in
            let cipherCount = activeCiphers.lazy.filter { $0.folderId == folder.id }.count
            return VaultListItem(
                id: folder.id,
                itemType: .group(.folder(id: folder.id, name: folder.name), cipherCount)
            )
        }

        let typesCardCount = activeCiphers.lazy.filter { $0.type == .card }.count
        let typesIdentityCount = activeCiphers.lazy.filter { $0.type == .identity }.count
        let typesLoginCount = activeCiphers.lazy.filter { $0.type == .login }.count
        let typesSecureNoteCount = activeCiphers.lazy.filter { $0.type == .secureNote }.count

        let types = [
            VaultListItem(id: "Types.Logins", itemType: .group(.login, typesLoginCount)),
            VaultListItem(id: "Types.Cards", itemType: .group(.card, typesCardCount)),
            VaultListItem(id: "Types.Identities", itemType: .group(.identity, typesIdentityCount)),
            VaultListItem(id: "Types.SecureNotes", itemType: .group(.secureNote, typesSecureNoteCount)),
        ]

        return [
            VaultListSection(id: "Favorites", items: ciphersFavorites, name: Localizations.favorites),
            VaultListSection(id: "Types", items: types, name: Localizations.types),
            VaultListSection(id: "Folders", items: folderItems, name: Localizations.folders),
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

    // MARK: Data Methods

    func addCipher(_ cipher: CipherView) async throws {
        let cipher = try await clientVault.ciphers().encrypt(cipherView: cipher)
        _ = try await cipherAPIService.addCipher(cipher)
        // TODO: BIT-92 Insert response into database instead of fetching sync.
        try await fetchSync()
    }

    func remove(userId: String?) async {
        await vaultTimeoutService.remove(userId: userId)
    }

    func updateCipher(_ updatedCipherView: CipherView) async throws {
        let updatedCipher = try await clientVault.ciphers().encrypt(cipherView: updatedCipherView)
        _ = try await cipherAPIService.updateCipher(updatedCipher)
        // TODO: BIT-92 Insert response into database instead of fetching sync.
        try await fetchSync()
    }

    // MARK: Publishers

    func vaultListPublisher() -> AsyncPublisher<AnyPublisher<[VaultListSection], Never>> {
        syncResponseSubject
            .asyncCompactMap { response in
                guard let response else { return nil }
                return try? await self.vaultListSections(from: response)
            }
            .eraseToAnyPublisher()
            .values
    }

    func vaultListPublisher(group: VaultListGroup) -> AsyncPublisher<AnyPublisher<[VaultListItem], Never>> {
        syncResponseSubject
            .asyncCompactMap { response in
                guard let response else { return nil }
                return try? await self.vaultListItems(group: group, from: response)
            }
            .eraseToAnyPublisher()
            .values
    }

    func cipherDetailsPublisher(id: String) -> AsyncPublisher<AnyPublisher<CipherView, Never>> {
        syncResponseSubject
            .asyncCompactMap { response in
                guard let cipher = response?.ciphers.first(where: { $0.id == id }) else { return nil }
                return try? await self.clientVault.ciphers().decrypt(cipher: Cipher(responseModel: cipher))
            }
            .eraseToAnyPublisher()
            .values
    }
}
