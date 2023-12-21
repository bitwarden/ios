import BitwardenSdk
import Combine
import Foundation

// MARK: - SyncService

/// A protocol for a service that manages syncing vault data with the API.
///
protocol SyncService: AnyObject {
    // MARK: Methods

    /// Clears any cached data in the service.
    ///
    func clearCachedData()

    /// Performs an API request to sync the user's vault data.
    ///
    func fetchSync() async throws

    /// A publisher for the sync response.
    ///
    /// - Returns: A publisher for the sync response.
    ///
    func syncResponsePublisher() -> AnyPublisher<SyncResponseModel?, Never>
}

// MARK: - DefaultSyncService

/// A default implementation of a `SyncService` which manages syncing vault data with the API.
///
class DefaultSyncService: SyncService {
    // MARK: Properties

    /// The service for managing the ciphers for the user.
    let cipherService: CipherService

    /// The client used by the application to handle encryption and decryption setup tasks.
    let clientCrypto: ClientCryptoProtocol

    /// The service for managing the collections for the user.
    let collectionService: CollectionService

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The service for managing the folders for the user.
    let folderService: FolderService

    /// The service for managing the sends for the user.
    let sendService: SendService

    /// The service used by the application to manage account state.
    let stateService: StateService

    /// The API service used to perform sync API requests.
    let syncAPIService: SyncAPIService

    /// A subject containing the sync response.
    var syncResponseSubject = CurrentValueSubject<SyncResponseModel?, Never>(nil)

    // MARK: Initialization

    /// Initializes a `DefaultSyncService`.
    ///
    /// - Parameters:
    ///   - cipherService: The service for managing the ciphers for the user.
    ///   - clientCrypto: The client used by the application to handle encryption and decryption setup tasks.
    ///   - collectionService: The service for managing the collections for the user.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - folderService: The service for managing the folders for the user.
    ///   - sendService: The service for managing the sends for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///   - syncAPIService: The API service used to perform sync API requests.
    ///
    init(
        cipherService: CipherService,
        clientCrypto: ClientCryptoProtocol,
        collectionService: CollectionService,
        errorReporter: ErrorReporter,
        folderService: FolderService,
        sendService: SendService,
        stateService: StateService,
        syncAPIService: SyncAPIService
    ) {
        self.cipherService = cipherService
        self.clientCrypto = clientCrypto
        self.collectionService = collectionService
        self.errorReporter = errorReporter
        self.folderService = folderService
        self.sendService = sendService
        self.stateService = stateService
        self.syncAPIService = syncAPIService
    }

    // MARK: Private

    /// Initializes the SDK's crypto for any organizations the users is a member of.
    ///
    /// - Parameter syncResponse: The sync response from the API.
    ///
    private func initializeOrganizationCrypto(syncResponse: SyncResponseModel) async {
        let organizationKeysById = syncResponse.profile?.organizations?
            .reduce(into: [String: String]()) { result, organization in
                guard let key = organization.key else { return }
                result[organization.id] = key
            } ?? [:]
        do {
            try await clientCrypto.initializeOrgCrypto(
                req: InitOrgCryptoRequest(organizationKeys: organizationKeysById)
            )
        } catch {
            errorReporter.log(error: error)
        }
    }
}

extension DefaultSyncService {
    func clearCachedData() {
        syncResponseSubject.value = nil
    }

    func fetchSync() async throws {
        let userId = try await stateService.getActiveAccountId()

        let response = try await syncAPIService.getSync()
        await initializeOrganizationCrypto(syncResponse: response)

        try await cipherService.replaceCiphers(response.ciphers, userId: userId)
        try await collectionService.replaceCollections(response.collections, userId: userId)
        try await folderService.replaceFolders(response.folders, userId: userId)
        try await sendService.replaceSends(response.sends, userId: userId)

        syncResponseSubject.value = response

        try await stateService.setLastSyncTime(Date(), userId: userId)
    }

    func syncResponsePublisher() -> AnyPublisher<SyncResponseModel?, Never> {
        syncResponseSubject.eraseToAnyPublisher()
    }
}
