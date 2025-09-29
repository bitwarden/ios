import BitwardenKit
import BitwardenSdk
import Combine

// MARK: - OrganizationService

/// A protocol for a `OrganizationService` which manages syncing and updates to the user's organizations.
///
protocol OrganizationService {
    /// Fetches the organizations for a user.
    ///
    /// - Returns: The organizations for a user.
    ///
    func fetchAllOrganizations() async throws -> [Organization]

    /// Fetches the organizations for a user.
    ///
    /// - Parameter userId: The user ID associated with the organizations.
    /// - Returns: The organizations for a user.
    ///
    func fetchAllOrganizations(userId: String) async throws -> [Organization]

    /// Initializes the SDK's crypto for any organizations the users is a member of, using the
    /// organizations already loaded into the data store.
    ///
    func initializeOrganizationCrypto() async throws

    /// Initializes the SDK's crypto for any organizations the users is a member of.
    ///
    /// - Parameter organizations: The user's organizations.
    ///
    func initializeOrganizationCrypto(organizations: [Organization]) async throws

    /// Replaces the persisted list of organizations for the user.
    ///
    /// - Parameters:
    ///   - organizations: The updated list of organizations for the user.
    ///   - userId: The user ID associated with the organizations.
    ///
    func replaceOrganizations(_ organizations: [ProfileOrganizationResponseModel], userId: String) async throws

    // MARK: Publishers

    /// A publisher for a user's organizations.
    ///
    /// - Returns: The list of the user's organizations.
    ///
    func organizationsPublisher() async throws -> AnyPublisher<[Organization], Error>
}

// MARK: - DefaultOrganizationService

class DefaultOrganizationService: OrganizationService {
    // MARK: Properties

    /// The service that handles common client functionality such as encryption and decryption.
    let clientService: ClientService

    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter

    /// The data store for managing the persisted organizations for the user.
    let organizationDataStore: OrganizationDataStore

    /// The service used by the application to manage account state.
    let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultOrganizationService`.
    ///
    /// - Parameters:
    ///   - clientService: The service that handles common client functionality such as encryption and decryption.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - organizationDataStore: The data store for managing the persisted organizations for the user.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        clientService: ClientService,
        errorReporter: ErrorReporter,
        organizationDataStore: OrganizationDataStore,
        stateService: StateService
    ) {
        self.clientService = clientService
        self.errorReporter = errorReporter
        self.organizationDataStore = organizationDataStore
        self.stateService = stateService
    }
}

extension DefaultOrganizationService {
    func fetchAllOrganizations() async throws -> [Organization] {
        let userId = try await stateService.getActiveAccountId()
        return try await fetchAllOrganizations(userId: userId)
    }

    func fetchAllOrganizations(userId: String) async throws -> [Organization] {
        try await organizationDataStore.fetchAllOrganizations(userId: userId)
    }

    func initializeOrganizationCrypto() async throws {
        try await initializeOrganizationCrypto(organizations: fetchAllOrganizations())
    }

    func initializeOrganizationCrypto(organizations: [Organization]) async throws {
        let organizationKeysById = organizations
            .reduce(into: [String: String]()) { result, organization in
                guard let key = organization.key else { return }
                result[organization.id] = key
            }
        do {
            try await clientService.crypto().initializeOrgCrypto(
                req: InitOrgCryptoRequest(organizationKeys: organizationKeysById)
            )
        } catch {
            errorReporter.log(error: error)
        }
    }

    func replaceOrganizations(_ organizations: [ProfileOrganizationResponseModel], userId: String) async throws {
        try await organizationDataStore.replaceOrganizations(organizations, userId: userId)
    }

    // MARK: Publishers

    func organizationsPublisher() async throws -> AnyPublisher<[Organization], Error> {
        let userID = try await stateService.getActiveAccountId()
        return organizationDataStore.organizationPublisher(userId: userID)
    }
}
