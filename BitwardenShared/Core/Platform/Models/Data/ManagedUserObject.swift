import CoreData

/// A protocol for a `ManagedObject` data model associated with a user that adds some convenience
/// methods for building `NSPersistentStoreRequest` for common CRUD operations.
///
protocol ManagedUserObject: ManagedObject {
    /// The value type (struct) associated with the managed object that is persisted in the database.
    associatedtype ValueType

    /// Returns a `NSPredicate` used for filtering by a user's ID.
    ///
    /// - Parameter userId: The user ID associated with the managed object.
    ///
    static func userIdPredicate(userId: String) -> NSPredicate

    /// Returns a `NSPredicate` used for filtering by a user and managed object ID.
    ///
    /// - Parameter userId: The user ID associated with the managed object.
    ///
    static func userIdAndIdPredicate(userId: String, id: String) -> NSPredicate

    /// Updates the managed object from its associated value type object and user ID.
    ///
    /// - Parameters:
    ///   - value: The value type object used to update the managed object.
    ///   - userId: The user ID associated with the object.
    ///
    func update(with value: ValueType, userId: String)
}

extension ManagedUserObject where Self: NSManagedObject {
    /// A `NSBatchInsertRequest` that inserts objects for the specified user.
    ///
    /// - Parameters:
    ///   - objects: The list of objects to insert.
    ///   - userId: The user associated with the objects to insert.
    /// - Returns: A `NSBatchInsertRequest` that inserts the objects for the user.
    ///
    static func batchInsertRequest(objects: [ValueType], userId: String) -> NSBatchInsertRequest {
        batchInsertRequest(objects: objects) { object, value in
            object.update(with: value, userId: userId)
        }
    }

    /// A `NSBatchDeleteRequest` that deletes all objects for the specified user.
    ///
    /// - Parameter userId: The user associated with the objects to delete.
    /// - Returns: A `NSBatchDeleteRequest` that deletes all objects for the user.
    ///
    static func deleteByUserIdRequest(userId: String) -> NSBatchDeleteRequest {
        let fetchRequest = fetchResultRequest(predicate: userIdPredicate(userId: userId))
        return NSBatchDeleteRequest(fetchRequest: fetchRequest)
    }

    /// A `NSFetchRequest` that fetches objects for the specified user matching an ID.
    ///
    /// - Parameters:
    ///   - id: The ID of the object to fetch.
    ///   - userId: The user associated with the object to fetch.
    /// - Returns: A `NSFetchRequest` that fetches all objects for the user.
    ///
    static func fetchByIdRequest(id: String, userId: String) -> NSFetchRequest<Self> {
        fetchRequest(predicate: userIdAndIdPredicate(userId: userId, id: id))
    }

    /// A `NSFetchRequest` that fetches all objects for the specified user.
    ///
    /// - Parameter userId: The user associated with the objects to delete.
    /// - Returns: A `NSFetchRequest` that fetches all objects for the user.
    ///
    static func fetchByUserIdRequest(userId: String) -> NSFetchRequest<Self> {
        fetchRequest(predicate: userIdPredicate(userId: userId))
    }
}
