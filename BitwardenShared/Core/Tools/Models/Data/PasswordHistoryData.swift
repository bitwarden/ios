import BitwardenSdk
import CoreData
import Foundation

/// A data model for persisting generated passwords.
///
class PasswordHistoryData: NSManagedObject, ManagedObject {
    // MARK: Properties

    /// The date that the password was last used.
    @NSManaged var lastUsedDate: Date?

    /// The generated password.
    @NSManaged var password: String?

    /// The ID of the user who generated the password.
    @NSManaged var userId: String?

    // MARK: Initialization

    /// Initializes a `PasswordHistoryData` object for insertion into the managed object context.
    ///
    /// - Parameters:
    ///   - context: The managed object context to insert the initialized object.
    ///   - userId: The ID of the user who created the object.
    ///   - passwordHistory: The password history data used to create the object.
    ///
    convenience init(
        context: NSManagedObjectContext,
        userId: String,
        passwordHistory: PasswordHistory
    ) {
        self.init(context: context)
        lastUsedDate = passwordHistory.lastUsedDate
        password = passwordHistory.password
        self.userId = userId
    }
}

extension PasswordHistoryData {
    /// A `NSSortDescriptor` that sorts the password history by the last used date in descending order.
    static var sortByLastUsedDateDescending: NSSortDescriptor {
        NSSortDescriptor(keyPath: \PasswordHistoryData.lastUsedDate, ascending: false)
    }

    /// A `NSBatchDeleteRequest` that deletes all `PasswordHistoryData` objects for the specified user.
    ///
    /// - Parameter userId: The user associated with the `PasswordHistoryData` objects to delete.
    /// - Returns: A `NSBatchDeleteRequest` that deletes all `PasswordHistoryData` objects for the user.
    ///
    static func deleteByUserIdRequest(userId: String) -> NSBatchDeleteRequest {
        let fetchRequest = fetchResultRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(PasswordHistoryData.userId), userId)
        return NSBatchDeleteRequest(fetchRequest: fetchRequest)
    }

    /// A `NSFetchRequest` that fetches all `PasswordHistoryData` objects for the specified user.
    ///
    /// - Parameter userId: The user associated with the `PasswordHistoryData` objects to delete.
    /// - Returns: A `NSFetchRequest` that fetches all `PasswordHistoryData` objects for the user.
    ///
    static func fetchByUserIdRequest(userId: String) -> NSFetchRequest<PasswordHistoryData> {
        let fetchRequest = fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == %@", #keyPath(PasswordHistoryData.userId), userId)
        return fetchRequest
    }
}
