import Foundation

/// API response model for collection details.
///
struct CollectionDetailsResponseModel: Codable, Equatable {
    // MARK: Properties

    /// An external identifier for the collection.
    let externalId: String?

    /// Whether the collection hides passwords.
    let hidePasswords: Bool

    /// The collection's identifier.
    let id: String?

    /// The collection's name.
    let name: String?

    /// The response object type.
    let object: String?

    /// The organization ID of the collection.
    let organizationId: String

    /// Whether the collection is read only.
    let readOnly: Bool
}
