import BitwardenSdk

// MARK: PendingAdminLoginRequest

/// The admin request that is waiting for approval
/// Saved in state for future reference
///
public struct PendingAdminLoginRequest: Codable, Equatable, Hashable {
    // MARK: Properties

    /// Access code
    let accessCode: String

    /// Fingerprint of the public key
    let fingerprint: String

    /// The id of the login request.
    let id: String

    /// Base64 encoded private key
    let privateKey: String

    /// Base64 encoded public key
    let publicKey: String

    init(id: String, authRequestResponse: AuthRequestResponse) {
        self.id = id
        accessCode = authRequestResponse.accessCode
        fingerprint = authRequestResponse.fingerprint
        privateKey = authRequestResponse.privateKey
        publicKey = authRequestResponse.publicKey
    }
}
