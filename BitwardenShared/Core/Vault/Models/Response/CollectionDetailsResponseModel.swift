import BitwardenKit
import Foundation

/// API response model for collection details.
///
struct CollectionDetailsResponseModel: Codable, Equatable {
    // MARK: Properties

    /// The offboarded user's email address to be used as name for the collection.
    let defaultUserCollectionEmail: String?

    /// An external identifier for the collection.
    let externalId: String?

    /// Whether the collection hides passwords.
    let hidePasswords: Bool

    /// The collection's identifier.
    let id: String

    /// Whether the collection can be managed by the user.
    var manage: Bool?

    /// The collection's name.
    let name: String

    /// The organization ID of the collection.
    let organizationId: String

    /// Whether the collection is read only.
    let readOnly: Bool

    /// The collection's type.
    @DefaultValue var type: CollectionType
}
