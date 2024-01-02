import BitwardenSdk
import CoreData
import Foundation

/// A data model for persisting folders.
///
class FolderData: NSManagedObject, ManagedObject, CodableModelData {
    typealias Model = FolderModelData

    // MARK: Properties

    /// The folder's identifier.
    @NSManaged var id: String?

    /// The data model encoded as JSON data.
    @NSManaged var modelData: Data?

    /// The ID of the user who owns the folder.
    @NSManaged var userId: String?

    // MARK: Initialization

    /// Initialize a `FolderData` object for insertion into the managed object context.
    ///
    /// - Parameters:
    ///   - context: The managed object context to insert the initialized object.
    ///   - userId: The user ID associated with the folder.
    ///   - folder: The `Folder` object used to create the object.
    ///
    convenience init(
        context: NSManagedObjectContext,
        userId: String,
        folder: Folder
    ) {
        self.init(context: context)
        id = folder.id
        model = FolderModelData(folder: folder)
        self.userId = userId
    }

    // MARK: Methods

    /// Updates the `FolderData` object from a `Folder` and user ID.
    ///
    /// - Parameters:
    ///   - folder: The `Folder` object used to update the `FolderData` instance.
    ///   - userId: The user ID associated with the folder.
    ///
    func update(with folder: Folder, userId: String) {
        id = folder.id
        model = FolderModelData(folder: folder)
        self.userId = userId
    }
}

extension FolderData {
    /// A `Codable` struct for encoding the folder's properties as JSON encoded data.
    struct FolderModelData: Codable {
        // MARK: Properties

        /// The folder's identifier.
        let id: String?

        /// The folder's name.
        let name: String?

        /// The date of the folder's last revision.
        let revisionDate: Date?

        /// Initialize a `FolderModelData` from a `Folder`.
        ///
        /// - Parameter folder: The `Folder` used to initialize the `FolderModelData`.
        ///
        init(folder: Folder) {
            id = folder.id
            name = folder.name
            revisionDate = folder.revisionDate
        }
    }
}

extension FolderData {
    /// Returns a `NSPredicate` used for filtering by a user's ID.
    ///
    /// - Parameter userId: The user ID associated with the folder.
    ///
    static func userIdPredicate(userId: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", #keyPath(FolderData.userId), userId)
    }

    /// Returns a `NSPredicate` used for filtering by a user and folder ID.
    ///
    /// - Parameter userId: The user ID associated with the folder.
    ///
    static func userIdAndIdPredicate(userId: String, id: String) -> NSPredicate {
        NSPredicate(format: "%K == %@ AND %K == %@", #keyPath(FolderData.userId), userId, #keyPath(FolderData.id), id)
    }
}

extension FolderData {
    /// A `NSBatchInsertRequest` that inserts `FolderData` objects for the specified user.
    ///
    /// - Parameters:
    ///   - folders: The list of `FolderData` objects to insert.
    ///   - userId: The user associated with the `FolderData` objects to insert.
    /// - Returns: A `NSBatchInsertRequest` that inserts `FolderData` objects for the user.
    ///
    static func batchInsertRequest(folders: [Folder], userId: String) throws -> NSBatchInsertRequest {
        try batchInsertRequest(objects: folders) { folderData, folder in
            folderData.update(with: folder, userId: userId)
        }
    }

    /// A `NSBatchDeleteRequest` that deletes all `FolderData` objects for the specified user.
    ///
    /// - Parameter userId: The user associated with the `FolderData` objects to delete.
    /// - Returns: A `NSBatchDeleteRequest` that deletes all `FolderData` objects for the user.
    ///
    static func deleteByUserIdRequest(userId: String) -> NSBatchDeleteRequest {
        let fetchRequest = fetchResultRequest(predicate: userIdPredicate(userId: userId))
        return NSBatchDeleteRequest(fetchRequest: fetchRequest)
    }

    /// A `NSFetchRequest` that fetches `FolderData` objects for the specified user matching an ID.
    ///
    /// - Parameters:
    ///   - id: The ID of the `FolderData` object to fetch.
    ///   - userId: The user associated with the `FolderData` objects to delete.
    /// - Returns: A `NSFetchRequest` that fetches all `FolderData` objects for the user.
    ///
    static func fetchByIdRequest(id: String, userId: String) -> NSFetchRequest<FolderData> {
        fetchRequest(predicate: userIdAndIdPredicate(userId: userId, id: id))
    }

    /// A `NSFetchRequest` that fetches all `FolderData` objects for the specified user.
    ///
    /// - Parameter userId: The user associated with the `FolderData` objects to delete.
    /// - Returns: A `NSFetchRequest` that fetches all `FolderData` objects for the user.
    ///
    static func fetchByUserIdRequest(userId: String) -> NSFetchRequest<FolderData> {
        fetchRequest(predicate: userIdPredicate(userId: userId))
    }
}
