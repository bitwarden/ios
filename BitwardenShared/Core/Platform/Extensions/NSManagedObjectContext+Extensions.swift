import CoreData

extension NSManagedObjectContext {
    /// Executes the batch delete request and merges any changes into the current context plus any
    /// additional contexts.
    ///
    /// - Parameters:
    ///   - batchDeleteRequest: The batch delete request to execute.
    ///   - additionalContexts: Any additional contexts other than the current to merge the changes into.
    ///
    func executeAndMergeChanges(
        _ batchDeleteRequest: NSBatchDeleteRequest,
        additionalContexts: [NSManagedObjectContext] = []
    ) throws {
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        let result = try execute(batchDeleteRequest) as? NSBatchDeleteResult
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self] + additionalContexts)
    }

    /// Saves the context if there are changes.
    func saveIfChanged() throws {
        guard hasChanges else { return }
        try save()
    }
}
