import CoreData
import Foundation

/// A data model for persisting authenticator items
///
class AuthenticatorItemData: NSManagedObject, ManagedUserObject, CodableModelData {
    typealias Model = AuthenticatorItemDataModel

    // MARK: Properties

    /// The item's ID
    @NSManaged var id: String

    /// The data model encoded as encrypted JSON data
    @NSManaged var modelData: Data?

    /// The ID of the user who owns the item
    @NSManaged var userId: String

    // MARK: Initialization

    /// Initialize an `AuthenticatorItemData` object for insertion into the managed object context
    ///
    /// - Parameters:
    ///   - context: The managed object context to insert the initialized item
    ///   - userId: The ID of the user who owns the item
    ///   - authenticatorItem: the `AuthenticatorItem` used to create the item
    convenience init(
        context: NSManagedObjectContext,
        userId: String,
        authenticatorItem: AuthenticatorItem
    ) throws {
        self.init(context: context)
        id = authenticatorItem.id
        model = try AuthenticatorItemDataModel(item: authenticatorItem)
        self.userId = userId
    }

    // MARK: Methods

    /// Updates the `AuthenticatorItemData` object from an `AuthenticatorItem` and user ID
    ///
    /// - Parameters:
    ///   - authenticatorItem: The `AuthenticatorItem` used to update the `AuthenticatorItemData` instance
    ///   - userId: The user ID associated with the item
    ///
    func update(with authenticatorItem: AuthenticatorItem, userId: String) throws {
        id = authenticatorItem.id
        model = try AuthenticatorItemDataModel(item: authenticatorItem)
        self.userId = userId
    }
}

extension AuthenticatorItemData {
    static func userIdPredicate(userId: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", #keyPath(AuthenticatorItemData.userId), userId)
    }

    static func userIdAndIdPredicate(userId: String, id: String) -> NSPredicate {
        NSPredicate(
            format: "%K == %@ AND %K == %@",
            #keyPath(AuthenticatorItemData.userId),
            userId,
            #keyPath(AuthenticatorItemData.id),
            id
        )
    }
}

struct AuthenticatorItemDataModel: Codable {
    // MARK: Types

    enum CodingKeys: String, CodingKey {
        case favorite
        case id
        case name
        case totpKey
        case username
    }

    // MARK: Properties

    let favorite: Bool
    let id: String
    let name: String
    let totpKey: String?
    let username: String?

    // MARK: Initialization

    init(item: AuthenticatorItem) throws {
        favorite = item.favorite
        id = item.id
        name = item.name
        totpKey = item.totpKey
        username = item.username
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        favorite = (try? container.decode(Bool.self, forKey: .favorite)) ?? false
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        totpKey = try container.decodeIfPresent(String.self, forKey: .totpKey)
        username = try container.decodeIfPresent(String.self, forKey: .username)
    }
}

/// Errors thrown from converting between SDK and app types.
///
enum DataMappingError: Error {
    /// Thrown if an object was unable to be constructed because the data was invalid.
    case invalidData

    /// Thrown if a required object identifier is nil.
    case missingId
}
