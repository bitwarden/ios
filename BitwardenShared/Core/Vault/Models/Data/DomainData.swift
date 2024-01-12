import CoreData
import Foundation

/// A data model for persisting domains.
///
class DomainData: NSManagedObject, ManagedObject, CodableModelData {
    typealias Model = DomainsResponseModel

    // MARK: Properties

    /// The data model encoded as JSON data.
    @NSManaged var modelData: Data?

    /// The ID of the user associated with the domains.
    @NSManaged var userId: String?

    // MARK: Initialization

    /// Initialize a `DomainData` object for insertion into the managed object context.
    ///
    /// - Parameters:
    ///   - context: The managed object context to insert the initialized object.
    ///   - userId: The user ID associated with the domains.
    ///   - domains: The `DomainsResponseModel` object used to create the object.
    ///
    convenience init(
        context: NSManagedObjectContext,
        userId: String,
        domains: DomainsResponseModel
    ) throws {
        self.init(context: context)
        model = domains
        self.userId = userId
    }
}

extension DomainData {
    /// A `NSFetchRequest` that fetches all objects for the specified user.
    ///
    /// - Parameter userId: The user associated with the objects to delete.
    /// - Returns: A `NSFetchRequest` that fetches all objects for the user.
    ///
    static func fetchByUserIdRequest(userId: String) -> NSFetchRequest<DomainData> {
        fetchRequest(predicate: userIdPredicate(userId: userId))
    }

    /// A `NSPredicate` that constrains a search for `DomainData` objects to the specified user.
    ///
    /// - Parameter userId: The user associated with the `DomainData` objects.
    /// - Returns: A `NSPredicate` that can be used to fetch `DomainData` objects for the user.
    ///
    static func userIdPredicate(userId: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", #keyPath(DomainData.userId), userId)
    }
}
