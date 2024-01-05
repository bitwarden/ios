import BitwardenSdk
import CoreData
import Foundation

/// A data model for persisting organizations.
///
class OrganizationData: NSManagedObject, ManagedUserObject, CodableModelData {
    typealias Model = ProfileOrganizationResponseModel

    // MARK: Properties

    /// The organization's identifier.
    @NSManaged var id: String?

    /// The data model encoded as JSON data.
    @NSManaged var modelData: Data?

    /// The ID of the user who owns the organization.
    @NSManaged var userId: String?

    // MARK: Initialization

    /// Initialize a `OrganizationData` object for insertion into the managed object context.
    ///
    /// - Parameters:
    ///   - context: The managed object context to insert the initialized object.
    ///   - userId: The user ID associated with the organization.
    ///   - organization: The `ProfileOrganizationResponseModel` object used to create the object.
    ///
    convenience init(
        context: NSManagedObjectContext,
        userId: String,
        organization: ProfileOrganizationResponseModel
    ) {
        self.init(context: context)
        id = organization.id
        model = organization
        self.userId = userId
    }

    // MARK: Methods

    /// Updates the `OrganizationData` object from a `Organization` and user ID.
    ///
    /// - Parameters:
    ///   - organization: The `ProfileOrganizationResponseModel` object used to update the
    ///     `OrganizationData` instance.
    ///   - userId: The user ID associated with the organization.
    ///
    func update(with organization: ProfileOrganizationResponseModel, userId: String) {
        id = organization.id
        model = organization
        self.userId = userId
    }
}

extension OrganizationData {
    static func userIdPredicate(userId: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", #keyPath(OrganizationData.userId), userId)
    }

    static func userIdAndIdPredicate(userId: String, id: String) -> NSPredicate {
        NSPredicate(
            format: "%K == %@ AND %K == %@",
            #keyPath(OrganizationData.userId),
            userId,
            #keyPath(OrganizationData.id),
            id
        )
    }
}
