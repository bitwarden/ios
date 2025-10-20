import CoreData

public extension NSManagedObjectContext {
    /// Executes the batch delete request and/or batch insert request and merges any changes into
    /// the current context plus any additional contexts.
    ///
    /// - Parameters:
    ///   - batchDeleteRequest: The batch delete request to execute.
    ///   - batchInsertRequest: The batch insert request to execute.
    ///   - additionalContexts: Any additional contexts other than the current to merge the changes into.
    ///
    func executeAndMergeChanges(
        batchDeleteRequest: NSBatchDeleteRequest? = nil,
        batchInsertRequest: NSBatchInsertRequest? = nil,
        additionalContexts: [NSManagedObjectContext] = [],
    ) throws {
        try executeAndMergeChanges(
            batchDeleteRequests: batchDeleteRequest.map { [$0] } ?? [],
            batchInsertRequests: batchInsertRequest.map { [$0] } ?? [],
            additionalContexts: additionalContexts,
        )
    }

    /// Executes the batch delete requests and/or batch insert requests and merges any changes into
    /// the current context plus any additional contexts.
    ///
    /// - Parameters:
    ///   - batchDeleteRequests: The batch delete requests to execute.
    ///   - batchInsertRequests: The batch insert requests to execute.
    ///   - additionalContexts: Any additional contexts other than the current to merge the changes into.
    ///
    func executeAndMergeChanges(
        batchDeleteRequests: [NSBatchDeleteRequest] = [],
        batchInsertRequests: [NSBatchInsertRequest] = [],
        additionalContexts: [NSManagedObjectContext] = [],
    ) throws {
        var changes: [AnyHashable: [NSManagedObjectID]] = [:]

        for batchDeleteRequest in batchDeleteRequests {
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            if let deleteResult = try execute(batchDeleteRequest) as? NSBatchDeleteResult,
               let objectIDs = deleteResult.result as? [NSManagedObjectID] {
                changes[NSDeletedObjectsKey, default: []].append(contentsOf: objectIDs)
            }
        }

        for batchInsertRequest in batchInsertRequests {
            batchInsertRequest.resultType = .objectIDs
            if let insertResult = try execute(batchInsertRequest) as? NSBatchInsertResult,
               let objectIDs = insertResult.result as? [NSManagedObjectID] {
                changes[NSInsertedObjectsKey, default: []].append(contentsOf: objectIDs)
            }
        }

        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self] + additionalContexts)
    }

    /// Performs the closure on the context's queue and saves the context if there are any changes.
    ///
    /// - Parameter closure: The closure to perform.
    ///
    func performAndSave(closure: @escaping () throws -> Void) async throws {
        try await perform {
            try closure()
            try self.saveIfChanged()
        }
    }

    /// Saves the context if there are changes.
    func saveIfChanged() throws {
        guard hasChanges else { return }
        try save()
    }
}
