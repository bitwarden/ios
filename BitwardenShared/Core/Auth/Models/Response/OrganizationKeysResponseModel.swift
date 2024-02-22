import Networking

// MARK: - OrganizationKeysResponseModel

/// API response model for fetching the organization's keys.
///
struct OrganizationKeysResponseModel: JSONResponse, Equatable {
    // MARK: Properties

    /// The organization's private key.
    let privateKey: String?

    /// The organization's public key.
    let publicKey: String
}
