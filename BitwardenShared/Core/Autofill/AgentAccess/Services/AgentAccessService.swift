// MARK: - AgentAccessService

/// A protocol for a service that runs the Agent Access client for the active account.
///
protocol AgentAccessService: AnyObject { // sourcery: AutoMockable
    /// Starts the client for the user: loads or creates the identity, registers it with the server
    /// and connects to the relay. Does nothing if the client is already running for the user.
    ///
    /// - Parameter userId: The ID of the user to start the client for.
    ///
    func start(userId: String) async throws

    /// Stops the client and resolves any pending requests as denied.
    ///
    func stop() async

    /// Whether the user's identity has the given fingerprint.
    ///
    /// - Parameters:
    ///   - userId: The ID of the user.
    ///   - fingerprint: The 64 character hex identity fingerprint.
    /// - Returns: `true` if the fingerprint belongs to the user's identity on this device.
    ///
    func ownsIdentity(userId: String, fingerprint: String) async -> Bool
}

// MARK: - DefaultAgentAccessService

/// The default implementation of `AgentAccessService`.
///
class DefaultAgentAccessService: AgentAccessService {
    func start(userId: String) async throws {}

    func stop() async {}

    func ownsIdentity(userId: String, fingerprint: String) async -> Bool {
        false
    }
}
