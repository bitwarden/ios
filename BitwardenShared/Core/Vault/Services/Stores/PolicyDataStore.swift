import CoreData

/// A protocol for a data store that handles performing data requests for policies.
///
protocol PolicyDataStore: AnyObject {
    /// Deletes all policies for the user.
    ///
    /// - Parameter userId: The user ID of the user associated with the policies.
    ///
    func deleteAllPolicies(userId: String) async throws

    /// Deletes all accepted-state policies (from `policiesNew`) for the user.
    ///
    /// - Parameter userId: The user ID of the user associated with the policies.
    ///
    func deleteAllPoliciesNew(userId: String) async throws

    /// Fetches all policies for the user.
    ///
    /// - Parameter userId: The user ID of the user associated with the policies.
    /// - Returns: The list of policies.
    ///
    func fetchAllPolicies(userId: String) async throws -> [Policy]

    /// Fetches all accepted-state policies (from `policiesNew`) for the user.
    ///
    /// - Parameter userId: The user ID of the user associated with the policies.
    /// - Returns: The list of accepted-state policies.
    ///
    func fetchAllPoliciesNew(userId: String) async throws -> [Policy]

    /// Replaces the list of policies for the user.
    ///
    /// - Parameters:
    ///   - policies: The list of policies.
    ///   - userId: The user ID of the user associated with the policies.
    ///
    func replacePolicies(_ policies: [PolicyResponseModel], userId: String) async throws

    /// Replaces the list of accepted-state policies (from `policiesNew`) for the user.
    ///
    /// - Parameters:
    ///   - policies: The list of accepted-state policies.
    ///   - userId: The user ID of the user associated with the policies.
    ///
    func replacePoliciesNew(_ policies: [PolicyResponseModel], userId: String) async throws
}

extension DataStore: PolicyDataStore {
    func deleteAllPolicies(userId: String) async throws {
        let fetchRequest = PolicyData.fetchResultRequest(predicate: PolicyData.userIdPredicate(userId: userId))
        try await executeBatchDelete(NSBatchDeleteRequest(fetchRequest: fetchRequest))
    }

    func deleteAllPoliciesNew(userId: String) async throws {
        try await executeBatchDelete(PolicyData.deletePoliciesNewByUserIdRequest(userId: userId))
    }

    func fetchAllPolicies(userId: String) async throws -> [Policy] {
        try await backgroundContext.perform {
            let fetchRequest = PolicyData.fetchByUserIdRequest(userId: userId)
            return try self.backgroundContext.fetch(fetchRequest).compactMap(Policy.init)
        }
    }

    func fetchAllPoliciesNew(userId: String) async throws -> [Policy] {
        try await backgroundContext.perform {
            let fetchRequest = PolicyData.fetchPoliciesNewByUserIdRequest(userId: userId)
            return try self.backgroundContext.fetch(fetchRequest).compactMap(Policy.init)
        }
    }

    func replacePolicies(_ policies: [PolicyResponseModel], userId: String) async throws {
        let deleteRequest = PolicyData.deleteByUserIdRequest(userId: userId)
        let insertRequest = try PolicyData.batchInsertRequest(objects: policies, userId: userId)
        try await executeBatchReplace(
            deleteRequest: deleteRequest,
            insertRequest: insertRequest,
        )
    }

    func replacePoliciesNew(_ policies: [PolicyResponseModel], userId: String) async throws {
        let deleteRequest = PolicyData.deletePoliciesNewByUserIdRequest(userId: userId)
        let insertRequest = PolicyData.batchInsertPoliciesNewRequest(policies, userId: userId)
        try await executeBatchReplace(
            deleteRequest: deleteRequest,
            insertRequest: insertRequest,
        )
    }
}
