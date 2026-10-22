import Combine
import Foundation

// MARK: - DefaultAgentAccessRepository

/// The default implementation of `AgentAccessRepository`.
///
class DefaultAgentAccessRepository: AgentAccessRepository {
    func isFeatureEnabled() async -> Bool {
        false
    }

    func isListeningEnabled() async -> Bool {
        false
    }

    func setListeningEnabled(_ enabled: Bool) async throws {
        throw AgentAccessError.featureDisabled
    }

    func relayURL() async -> String {
        AgentAccessConstants.defaultRelayURL
    }

    func setRelayURL(_ url: String) async throws {
        throw AgentAccessError.featureDisabled
    }

    func statusPublisher() -> AnyPublisher<AgentAccessConnectionStatus, Never> {
        Just(.disabled).eraseToAnyPublisher()
    }

    func createPairing(kind: AgentAccessPairingKind, name: String) async throws -> AgentAccessPairing {
        throw AgentAccessError.featureDisabled
    }

    func pairingEventsPublisher() -> AnyPublisher<AgentAccessPairingEvent, Never> {
        Empty().eraseToAnyPublisher()
    }

    func answerFingerprintVerification(id: String, approved: Bool) {}

    func connections() async throws -> [AgentAccessConnection] {
        []
    }

    func revokeConnection(fingerprint: String) async throws {
        throw AgentAccessError.featureDisabled
    }

    func pendingRequestsPublisher() -> AnyPublisher<[AgentAccessApprovalRequest], Never> {
        Just([]).eraseToAnyPublisher()
    }

    func pendingRequest(id: String) async -> AgentAccessApprovalRequest? {
        nil
    }

    func candidates(for requestId: String) async throws -> [AgentAccessCandidate] {
        throw AgentAccessError.requestNotFound
    }

    func answer(requestId: String, decision: AgentAccessDecision) async throws {
        throw AgentAccessError.requestNotFound
    }

    func autoApproveRules() async -> [AgentAccessAutoApproveRule] {
        []
    }

    func removeAutoApproveRule(id: String) async {}

    func auditLog() async throws -> [AgentAccessAuditEntry] {
        []
    }

    func clearAuditLog() async throws {}

    func appDidBecomeActive() async {}

    func appDidEnterBackground() async {}

    func activeAccountChanged(userId: String?) async {}

    func notificationTapped(userId: String) async {}
}
