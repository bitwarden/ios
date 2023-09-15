import Networking

/// API response model for the GET /sync request.
///
struct SyncResponseModel: JSONResponse, Equatable {
    // MARK: Properties

    /// The user's list of ciphers.
    let ciphers: [CipherDetailsResponseModel]

    /// The user's list of collections.
    let collections: [CollectionDetailsResponseModel]

    /// Domain details.
    let domains: DomainsResponseModel?

    /// The user's list of folders.
    let folders: [FolderResponseModel]

    /// Policies that apply to the user.
    let policies: [PolicyResponseModel]

    /// The user's profile.
    let profile: ProfileResponseModel?

    /// The user's list of sends.
    let sends: [SendResponseModel]
}
