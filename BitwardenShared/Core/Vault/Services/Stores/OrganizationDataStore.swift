import BitwardenSdk
import Combine
import CoreData

// MARK: - OrganizationDataStore

/// A protocol for a data store that handles performing data requests for organizations.
///
protocol OrganizationDataStore: AnyObject {
    /// Deletes all `Organization` objects for a specific user.
    ///
    /// - Parameter userId: The user ID of the user associated with the objects to delete.
    ///
    func deleteAllOrganizations(userId: String) async throws

    /// A publisher for a user's organization objects.
    ///
    /// - Parameter userId: The user ID of the user to associated with the objects to fetch.
    /// - Returns: A publisher for the user's organizations.
    ///
    func organizationPublisher(userId: String) -> AnyPublisher<[Organization], Error>

    /// Fetches the organizations that are available to the user.
    ///
    /// - Parameter userId: The user ID of the user associated with the organizations to fetch.
    /// - Returns: The organizations that are available to the user.
    ///
    func fetchAllOrganizations(userId: String) async throws -> [Organization]

    /// Replaces a list of `Organization` objects for a user.
    ///
    /// - Parameters:
    ///   - organizations: The list of organizations to replace any existing organizations.
    ///   - userId: The user ID of the user associated with the organizations.
    ///
    func replaceOrganizations(_ organizations: [ProfileOrganizationResponseModel], userId: String) async throws
}

extension DataStore: OrganizationDataStore {
    func deleteAllOrganizations(userId: String) async throws {
        try await executeBatchDelete(OrganizationData.deleteByUserIdRequest(userId: userId))
    }

    func organizationPublisher(userId: String) -> AnyPublisher<[Organization], Error> {
        let fetchRequest = OrganizationData.fetchByUserIdRequest(userId: userId)
        // A sort descriptor is needed by `NSFetchedResultsController`.
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \OrganizationData.id, ascending: true)]
        return FetchedResultsPublisher(
            context: persistentContainer.viewContext,
            request: fetchRequest
        )
        .tryMap { try $0.compactMap(Organization.init) }
        .eraseToAnyPublisher()
    }

    func fetchAllOrganizations(userId: String) async throws -> [Organization] {
        try await backgroundContext.perform {
            let fetchRequest = OrganizationData.fetchByUserIdRequest(userId: userId)
            return try self.backgroundContext.fetch(fetchRequest).compactMap(Organization.init)
        }
    }

    func replaceOrganizations(_ organizations: [ProfileOrganizationResponseModel], userId: String) async throws {
        let deleteRequest = OrganizationData.deleteByUserIdRequest(userId: userId)
        let insertRequest = try OrganizationData.batchInsertRequest(objects: organizations, userId: userId)
        try await executeBatchReplace(
            deleteRequest: deleteRequest,
            insertRequest: insertRequest
        )
    }
}
