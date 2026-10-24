import Networking

// MARK: - AgentAccessAPIService

/// A protocol for an API service used to register Agent Access identities with the server.
///
protocol AgentAccessAPIService { // sourcery: AutoMockable
    /// Registers an identity fingerprint for the active user so the server can send push
    /// notifications when a request is waiting at the relay.
    ///
    /// - Parameter proof: The identity fingerprint with the proof that the device holds its key.
    ///
    func registerIdentity(proof: AgentAccessIdentityProof) async throws

    /// Removes the registration of an identity fingerprint of the active user.
    ///
    /// - Parameter fingerprint: The 64 character lowercase hex identity fingerprint.
    ///
    func unregisterIdentity(fingerprint: String) async throws
}

extension APIService: AgentAccessAPIService {
    func registerIdentity(proof: AgentAccessIdentityProof) async throws {
        _ = try await apiService.send(
            RegisterAgentAccessIdentityRequest(
                requestBody: .init(
                    fingerprint: proof.fingerprint,
                    publicKey: proof.publicKey,
                    signature: proof.signature,
                ),
            ),
        )
    }

    func unregisterIdentity(fingerprint: String) async throws {
        _ = try await apiService.send(UnregisterAgentAccessIdentityRequest(fingerprint: fingerprint))
    }
}
