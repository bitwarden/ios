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

    /// Policies that apply to the user. This is the legacy list, superseded by `policiesNew`.
    /// See `effectivePolicies`.
    let policies: [PolicyResponseModel]?

    /// The new policies list including accepted-state members from the server-side flag.
    /// See `effectivePolicies` for the fallback to `policies` when absent.
    let policiesNew: [PolicyResponseModel]?

    /// The user's profile.
    let profile: ProfileResponseModel?

    /// The user's list of sends.
    let sends: [SendResponseModel]

    /// The user's decryption info.
    let userDecryption: UserDecryptionResponseModel?

    // MARK: Computed Properties

    /// The effective list of policies for the user.
    ///
    /// Prefers `policiesNew` (which includes accepted-state members) over the legacy `policies`
    /// list, which is used when the server doesn't return `policiesNew`. Returns an empty list
    /// when neither is present.
    ///
    var effectivePolicies: [PolicyResponseModel] {
        policiesNew ?? policies ?? []
    }
}
