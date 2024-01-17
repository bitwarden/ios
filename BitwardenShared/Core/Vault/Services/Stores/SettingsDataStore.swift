import CoreData

/// A protocol for a data store that handles performing data requests for settings.
///
protocol SettingsDataStore: AnyObject {
    /// Deletes the list of equivalent domains for the user.
    ///
    /// - Parameter userId: The user ID of the user associated with the domains.
    ///
    func deleteEquivalentDomains(userId: String) async throws

    /// Fetches the list of equivalent domains for the user.
    ///
    /// - Parameter userId: The user ID of the user associated with the domains.
    /// - Returns: The list of equivalent domains.
    ///
    func fetchEquivalentDomains(userId: String) async throws -> DomainsResponseModel?

    /// Replaces the list of equivalent domains for the user.
    ///
    /// - Parameters:
    ///   - domains: The list of equivalent domains.
    ///   - userId: The user ID of the user associated with the domains.
    ///
    func replaceEquivalentDomains(_ domains: DomainsResponseModel, userId: String) async throws
}

extension DataStore: SettingsDataStore {
    func deleteEquivalentDomains(userId: String) async throws {
        let fetchRequest = DomainData.fetchResultRequest(predicate: DomainData.userIdPredicate(userId: userId))
        try await executeBatchDelete(NSBatchDeleteRequest(fetchRequest: fetchRequest))
    }

    func fetchEquivalentDomains(userId: String) async throws -> DomainsResponseModel? {
        try await backgroundContext.perform {
            try self.backgroundContext.fetch(DomainData.fetchByUserIdRequest(userId: userId))
                .compactMap(\.model)
                .first
        }
    }

    func replaceEquivalentDomains(_ domains: DomainsResponseModel, userId: String) async throws {
        try await backgroundContext.performAndSave {
            _ = try DomainData(context: self.backgroundContext, userId: userId, domains: domains)
        }
    }
}
