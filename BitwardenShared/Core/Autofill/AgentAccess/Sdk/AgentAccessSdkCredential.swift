import Foundation

// MARK: - AgentAccessSdkCredential

/// The credential values returned to the SDK when a request is approved. Never persisted or logged.
///
struct AgentAccessSdkCredential: Equatable, Sendable {
    /// The username of the vault item.
    let username: String?

    /// The password of the vault item.
    let password: String?

    /// The ID of the vault item.
    let credentialId: String?

    /// The domain of the vault item.
    let domain: String?
}
