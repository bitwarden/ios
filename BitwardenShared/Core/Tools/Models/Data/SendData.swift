import BitwardenSdk
import CoreData
import Foundation

/// A data model for persisting sends.
///
class SendData: NSManagedObject, ManagedUserObject, CodableModelData {
    typealias Model = SendResponseModel

    // MARK: Properties

    /// The sends's identifier.
    @NSManaged var id: String?

    /// The data model encoded as JSON data.
    @NSManaged var modelData: Data?

    /// The ID of the user who owns the send.
    @NSManaged var userId: String?

    // MARK: Initialization

    /// Initialize a `SendData` object for insertion into the managed object context.
    ///
    /// - Parameters:
    ///   - context: The managed object context to insert the initialized object.
    ///   - userId: The user ID associated with the send.
    ///   - send: The `Send` object used to create the object.
    ///
    convenience init(
        context: NSManagedObjectContext,
        userId: String,
        send: Send
    ) {
        self.init(context: context)
        id = send.id
        model = SendResponseModel(send: send)
        self.userId = userId
    }

    // MARK: Methods

    /// Updates the `SendData` object from a `Send` and user ID.
    ///
    /// - Parameters:
    ///   - send: The `Send` object used to update the `SendData` instance.
    ///   - userId: The user ID associated with the send.
    ///
    func update(with send: Send, userId: String) {
        id = send.id
        model = SendResponseModel(send: send)
        self.userId = userId
    }
}

extension SendData {
    static func userIdPredicate(userId: String) -> NSPredicate {
        NSPredicate(format: "%K == %@", #keyPath(SendData.userId), userId)
    }

    static func userIdAndIdPredicate(userId: String, id: String) -> NSPredicate {
        NSPredicate(
            format: "%K == %@ AND %K == %@",
            #keyPath(SendData.userId),
            userId,
            #keyPath(SendData.id),
            id
        )
    }
}
