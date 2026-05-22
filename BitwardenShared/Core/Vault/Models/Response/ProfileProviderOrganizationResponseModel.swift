import Foundation

/// API response model for a provider organization listed on a user profile.
///
/// This type is used to identify organizations that the user has access to via a provider
/// relationship, enabling `isProviderUser` coalescing during sync.
///
struct ProfileProviderOrganizationResponseModel: Codable, Equatable {
    // MARK: Properties

    /// The organization's identifier.
    let id: String
}
