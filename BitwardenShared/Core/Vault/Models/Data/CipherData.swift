import BitwardenSdk
import CoreData
import Foundation

/// A data model for persisting ciphers.
///
class CipherData: NSManagedObject, ManagedUserObject, CodableModelData {
    typealias Model = CipherDetailsResponseModel

    // MARK: Properties

    /// The cipher's identifier.
    @NSManaged var id: String?

    /// The data model encoded as JSON data.
    @NSManaged var modelData: Data?

    /// The ID of the user who owns the cipher.
    @NSManaged var userId: String?

    // MARK: Initialization

    /// Initialize a `CipherData` object for insertion into the managed object context.
    ///
    /// - Parameters:
    ///   - context: The managed object context to insert the initialized object.
    ///   - userId: The user ID associated with the cipher.
    ///   - cipher: The `Cipher` object used to create the object.
    ///
    convenience init(
        context: NSManagedObjectContext,
        userId: String,
        cipher: Cipher
    ) throws {
        self.init(context: context)
        id = cipher.id
        model = try CipherDetailsResponseModel(cipher: cipher)
        self.userId = userId
    }

    // MARK: Methods

    /// Updates the `CipherData` object from a `Cipher` and user ID.
    ///
    /// - Parameters:
    ///   - cipher: The `Cipher` object used to update the `CipherData` instance.
    ///   - userId: The user ID associated with the cipher.
    ///
    func update(with cipher: Cipher, userId: String) throws {
        id = cipher.id
        model = try CipherDetailsResponseModel(cipher: cipher)
        self.userId = userId
    }
}

extension CipherData {
    static func userIdPredicate(userId: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", #keyPath(CipherData.userId), userId)
    }

    static func userIdAndIdPredicate(userId: String, id: String) -> NSPredicate {
        NSPredicate(
            format: "%K == %@ AND %K == %@",
            #keyPath(CipherData.userId),
            userId,
            #keyPath(CipherData.id),
            id
        )
    }
}
