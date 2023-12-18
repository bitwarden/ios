import CoreData

extension NSManagedObjectContext {
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
        additionalContexts: [NSManagedObjectContext] = []
    ) throws {
        var changes: [AnyHashable: Any] = [:]

        if let batchDeleteRequest {
            batchDeleteRequest.resultType = .resultTypeObjectIDs
            if let deleteResult = try execute(batchDeleteRequest) as? NSBatchDeleteResult {
                changes[NSDeletedObjectsKey] = deleteResult.result as? [NSManagedObjectID] ?? []
            }
        }

        if let batchInsertRequest {
            batchInsertRequest.resultType = .objectIDs
            if let insertResult = try execute(batchInsertRequest) as? NSBatchInsertResult {
                changes[NSInsertedObjectsKey] = insertResult.result as? [NSManagedObjectID] ?? []
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
