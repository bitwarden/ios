import BitwardenSdk
import CoreData
import Foundation

/// A data model for persisting collections.
///
class CollectionData: NSManagedObject, ManagedUserObject, CodableModelData {
    typealias Model = CollectionDetailsResponseModel

    // MARK: Properties

    /// The collection's identifier.
    @NSManaged var id: String?

    /// The data model encoded as JSON data.
    @NSManaged var modelData: Data?

    /// The ID of the user who owns the collection.
    @NSManaged var userId: String?

    // MARK: Initialization

    /// Initialize a `CollectionData` object for insertion into the managed object context.
    ///
    /// - Parameters:
    ///   - context: The managed object context to insert the initialized object.
    ///   - userId: The user ID associated with the collection.
    ///   - collection: The `Collection` object used to create the object.
    ///
    convenience init(
        context: NSManagedObjectContext,
        userId: String,
        collection: Collection
    ) {
        self.init(context: context)
        id = collection.id
        model = CollectionDetailsResponseModel(collection: collection)
        self.userId = userId
    }

    // MARK: Methods

    /// Updates the `CollectionData` object from a `Collection` and user ID.
    ///
    /// - Parameters:
    ///   - collection: The `Collection` object used to update the `CollectionData` instance.
    ///   - userId: The user ID associated with the collection.
    ///
    func update(with collection: Collection, userId: String) {
        id = collection.id
        model = CollectionDetailsResponseModel(collection: collection)
        self.userId = userId
    }
}

extension CollectionData {
    static func userIdPredicate(userId: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", #keyPath(CollectionData.userId), userId)
    }

    static func userIdAndIdPredicate(userId: String, id: String) -> NSPredicate {
        NSPredicate(
            format: "%K == %@ AND %K == %@",
            #keyPath(CollectionData.userId),
            userId,
            #keyPath(CollectionData.id),
            id
        )
    }
}
