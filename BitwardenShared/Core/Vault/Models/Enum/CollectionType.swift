import BitwardenKit

/// An enum describing the type of collection assigned to user(s) or group(s).
///
enum CollectionType: Int, Codable {
    /// Default collection type. Can be assigned by an organization to user(s) or group(s).
    case sharedCollection = 0

    /// Default collection assigned to a user for an organization that has
    /// OrganizationDataOwnership (formerly PersonalOwnership) policy enabled.
    case defaultUserCollection = 1
}

// MARK: - DefaultValueProvider

extension CollectionType: DefaultValueProvider {
    static var defaultValue: CollectionType { .sharedCollection }
}
