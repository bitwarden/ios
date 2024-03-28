import BitwardenSdk

// MARK: PendingAdminLoginRequest

struct PendingAdminLoginRequest: Codable, Equatable, Hashable {
    // MARK: Properties

    /// The id of the login request.
    let id: String

    /// Base64 encoded private key
    let privateKey: String

    /// Base64 encoded public key
    let publicKey: String

    /// Fingerprint of the public key
    let fingerprint: String

    /// Access code
    let accessCode: String

    init(id: String, authRequestResponse: AuthRequestResponse) {
        self.id = id
        privateKey = authRequestResponse.privateKey
        publicKey = authRequestResponse.publicKey
        fingerprint = authRequestResponse.fingerprint
        accessCode = authRequestResponse.accessCode
    }
}
