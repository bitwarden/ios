/// An enum describing if the user should be re-prompted prior to using the cipher password.
///
enum CollectionType: Int, Codable {
    /// Default collection type. Can be assigned by an organization to user(s) or group(s)
    case sharedCollection = 0

    /// Default collection assigned to a user for an organization that has
    /// OrganizationDataOwnership (formerly PersonalOwnership) policy enabled.
    case defaultUserCollection = 1
}
