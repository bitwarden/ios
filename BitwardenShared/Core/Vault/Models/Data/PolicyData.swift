import BitwardenSdk
import CoreData
import Foundation

/// A data model for persisting policies.
///
class PolicyData: NSManagedObject, ManagedUserObject, CodableModelData {
    typealias Model = PolicyResponseModel

    // MARK: Properties

    /// The policy's identifier.
    @NSManaged var id: String?

    /// The data model encoded as JSON data.
    @NSManaged var modelData: Data?

    /// The ID of the user who owns the policy.
    @NSManaged var userId: String?

    // MARK: Initialization

    /// Initialize a `PolicyData` object for insertion into the managed object context.
    ///
    /// - Parameters:
    ///   - context: The managed object context to insert the initialized object.
    ///   - userId: The user ID associated with the policy.
    ///   - policy: The `PolicyResponseModel` object used to create the object.
    ///
    convenience init(
        context: NSManagedObjectContext,
        userId: String,
        policy: PolicyResponseModel
    ) {
        self.init(context: context)
        id = policy.id
        model = policy
        self.userId = userId
    }

    // MARK: Methods

    /// Updates the `PolicyData` object from a `Policy` and user ID.
    ///
    /// - Parameters:
    ///   - policy: The `PolicyResponseModel` object used to update the `PolicyData` instance.
    ///   - userId: The user ID associated with the policy.
    ///
    func update(with policy: PolicyResponseModel, userId: String) {
        id = policy.id
        model = policy
        self.userId = userId
    }
}

extension PolicyData {
    static func userIdPredicate(userId: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", #keyPath(PolicyData.userId), userId)
    }

    static func userIdAndIdPredicate(userId: String, id: String) -> NSPredicate {
        NSPredicate(
            format: "%K == %@ AND %K == %@",
            #keyPath(PolicyData.userId),
            userId,
            #keyPath(PolicyData.id),
            id
        )
    }
}
