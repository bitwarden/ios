import Foundation

// MARK: - AgentAccessSdkHandler

/// The callbacks the SDK client makes into the app. Every method is called synchronously on a
/// thread owned by the SDK (never the main thread or a Swift concurrency thread), and may block.
///
protocol AgentAccessSdkHandler: AnyObject, Sendable {
    /// Returns the cached connection for a remote agent, if any.
    func connection(fingerprint: String) -> AgentAccessStoredConnection?

    /// Returns the credential to send for a request, or `nil` to deny it. May block until the user decides.
    func credential(for query: AgentAccessQuery, remoteFingerprint: String) -> AgentAccessSdkCredential?

    /// Handles a status event.
    func handle(event: AgentAccessSdkEvent)

    /// Handles a security relevant event.
    func handle(auditEvent: AgentAccessSdkAuditEvent)

    /// Returns all cached connections.
    func listConnections() -> [AgentAccessStoredConnection]

    /// Loads the identity bytes, or `nil` if there is no identity yet.
    func loadIdentity() -> Data?

    /// Saves or replaces a cached connection.
    func saveConnection(_ connection: AgentAccessStoredConnection) throws

    /// Saves the identity bytes.
    func saveIdentity(_ identity: Data) throws

    /// Updates the last connected time of a cached connection.
    func updateConnection(fingerprint: String, lastConnectedAt: UInt64) throws

    /// Decides whether to accept a rendezvous pairing. May block until the user decides.
    func verifyFingerprint(code: String, remoteFingerprint: String?) -> Bool
}
