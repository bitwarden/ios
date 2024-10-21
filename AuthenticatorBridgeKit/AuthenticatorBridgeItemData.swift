import CoreData
import Foundation

/// A data model for persisting authenticator items into the shared CoreData store.
///
public class AuthenticatorBridgeItemData: NSManagedObject, CodableModelData {
    public typealias Model = AuthenticatorBridgeItemDataModel

    // MARK: Properties

    /// The item's ID
    @NSManaged public var id: String

    /// The data model encoded as encrypted JSON data
    @NSManaged public var modelData: Data?

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
        model = authenticatorItem
        self.userId = userId
    }
}

// MARK: - ManagedUserObject

extension AuthenticatorBridgeItemData: ManagedUserObject {
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

    /// Updates the object with the properties from the `value` struct and the given `userId`
    ///
    /// - Parameters:
    ///   - value: the `AuthenticatorBridgeItemDataModel` to use in updating the object
    ///   - userId: userId to update this object with.
    ///
    func update(with value: AuthenticatorBridgeItemDataModel, userId: String) throws {
        id = value.id
        model = value
        self.userId = userId
    }
}
