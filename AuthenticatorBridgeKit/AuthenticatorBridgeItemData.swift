import CoreData
import Foundation

/// A data model for persisting authenticator items into the shared CoreData store.
///
public class AuthenticatorBridgeItemData: NSManagedObject {
    // MARK: Properties

    /// The item's ID
    @NSManaged public var id: String

    /// The decoded object that is stored in modelData.
    public var model: AuthenticatorBridgeItemDataModel {
        get throws {
            try JSONDecoder().decode(AuthenticatorBridgeItemDataModel.self, from: modelData)
        }
    }

    /// The data model encoded as encrypted JSON data
    @NSManaged public var modelData: Data

    /// The ID of the user who owns the item
    @NSManaged public var userId: String

    // MARK: Initialization

    /// Initialize an `AuthenticatorBridgeItemData` object for insertion into the managed object context
    ///
    /// - Parameters:
    ///   - context: The managed object context to insert the initialized item
    ///   - userId: The ID of the user who owns the item
    ///   - authenticatorItem: the `AuthenticatorBridgeItemDataModel` used to create the item
    convenience init(
        context: NSManagedObjectContext,
        userId: String,
        authenticatorItem: AuthenticatorBridgeItemDataModel
    ) throws {
        self.init(context: context)
        id = authenticatorItem.id
        modelData = try JSONEncoder().encode(authenticatorItem)
        self.userId = userId
    }

    // MARK: Methods

    /// Updates the `AuthenticatorBridgeItemData` object from an `AuthenticatorBridgeItemDataModel` and user ID
    ///
    /// - Parameters:
    ///   - authenticatorItem: The `AuthenticatorBridgeItemDataModel` used to update
    ///   the `AuthenticatorBridgeItemData` instance
    ///   - userId: The user ID associated with the item
    ///
    public func update(with authenticatorItem: AuthenticatorBridgeItemDataModel, userId: String) throws {
        id = authenticatorItem.id
        modelData = try JSONEncoder().encode(authenticatorItem)
        self.userId = userId
    }
}

public extension AuthenticatorBridgeItemData {
    /// The name of the entity of the managed object, as defined in the data model.
    static var entityName: String {
        String(describing: self)
    }

    /// A `NSBatchInsertRequest` that inserts objects for the specified user.
    ///
    /// - Parameters:
    ///   - objects: The list of objects to insert.
    ///   - userId: The user associated with the objects to insert.
    /// - Returns: A `NSBatchInsertRequest` that inserts the objects for the user.
    ///
    static func batchInsertRequest(
        objects: [AuthenticatorBridgeItemDataModel],
        userId: String
    ) throws -> NSBatchInsertRequest {
        var index = 0
        var errorToThrow: Error?

        let insertRequest = NSBatchInsertRequest(
            entityName: AuthenticatorBridgeItemData.entityName
        ) { (managedObject: NSManagedObject) -> Bool in

            if let managedObject = (managedObject as? AuthenticatorBridgeItemData) {
                guard index < objects.count else { return true }
                defer { index += 1 }

                do {
                    try managedObject.update(with: objects[index], userId: userId)
                } catch {
                    // The error can't be thrown directly in this closure, so capture it, return
                    // from the closure, and then throw it.
                    errorToThrow = error
                    return true
                }
            }

            return false
        }

        if let errorToThrow {
            throw errorToThrow
        }

        return insertRequest
    }

    /// A `NSBatchDeleteRequest` that deletes all objects for the specified user.
    ///
    /// - Parameter userId: The user associated with the objects to delete.
    /// - Returns: A `NSBatchDeleteRequest` that deletes all objects for the user.
    ///
    static func deleteByUserIdRequest(userId: String) -> NSBatchDeleteRequest {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(
            entityName: AuthenticatorBridgeItemData.entityName
        )
        fetchRequest.predicate = AuthenticatorBridgeItemData.userIdPredicate(userId: userId)
        return NSBatchDeleteRequest(fetchRequest: fetchRequest)
    }

    /// A `NSFetchRequest` that fetches objects for the specified user matching an ID.
    ///
    /// - Parameters:
    ///   - id: The Id of the object to fetch.
    ///   - userId: The user associated with the object to fetch.
    /// - Returns: A `NSFetchRequest` that fetches all objects for the user.
    ///
    static func fetchByIdRequest(
        id: String,
        userId: String
    ) -> NSFetchRequest<AuthenticatorBridgeItemData> {
        let fetchRequest = NSFetchRequest<AuthenticatorBridgeItemData>(
            entityName: AuthenticatorBridgeItemData.entityName
        )
        fetchRequest.predicate = AuthenticatorBridgeItemData.userIdAndIdPredicate(
            userId: userId,
            id: id
        )
        return fetchRequest
    }

    /// A `NSFetchRequest` that fetches all `AuthenticatorBridgeItemData` for the specified user.
    ///
    /// - Parameter userId: The user associated with the objects to fetch.
    /// - Returns: A `NSFetchRequest` that fetches all objects for the user.
    ///
    static func fetchByUserIdRequest(userId: String) -> NSFetchRequest<AuthenticatorBridgeItemData> {
        let fetchRequest = NSFetchRequest<AuthenticatorBridgeItemData>(
            entityName: AuthenticatorBridgeItemData.entityName
        )
        fetchRequest.predicate = AuthenticatorBridgeItemData.userIdPredicate(userId: userId)
        return fetchRequest
    }

    /// Create an NSPredicate based on both the userId and id properties.
    ///
    /// - Parameters:
    ///   - userId: The userId to match in the predicate
    ///   - id: The id to match in the predicate
    /// - Returns: The NSPredicate for searching/filtering by userId and id
    ///
    static func userIdAndIdPredicate(userId: String, id: String) -> NSPredicate {
        NSPredicate(
            format: "%K == %@ AND %K == %@",
            #keyPath(AuthenticatorBridgeItemData.userId),
            userId,
            #keyPath(AuthenticatorBridgeItemData.id),
            id
        )
    }

    /// Create an NSPredicate based on the userId property.
    ///
    /// - Parameter userId: The userId to match in the predicate
    /// - Returns: The NSPredicate for searching/filtering by userId
    ///
    static func userIdPredicate(userId: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", #keyPath(AuthenticatorBridgeItemData.userId), userId)
    }
}
