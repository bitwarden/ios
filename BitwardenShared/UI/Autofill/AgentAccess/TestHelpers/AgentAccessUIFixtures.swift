import Foundation

@testable import BitwardenShared

// MARK: - AgentAccessUIFixtures

/// Sample values of the Agent Access models for the UI tests.
///
enum AgentAccessUIFixtures {
    /// A 64 character fingerprint.
    static let fingerprint = String(repeating: "ab", count: 32)

    /// A fixed date that tests can rely on.
    static let referenceDate = Date(timeIntervalSince1970: 1_700_000_000)

    /// A pending request.
    static func approvalRequest(
        id: String = "request-1",
        connectionName: String = "Codex",
        query: AgentAccessQuery = .domain("example.com"),
        expiresAt: Date = Date.now.addingTimeInterval(100),
    ) -> AgentAccessApprovalRequest {
        AgentAccessApprovalRequest(
            id: id,
            userId: "user-1",
            connectionFingerprint: fingerprint,
            connectionName: connectionName,
            query: query,
            receivedAt: expiresAt.addingTimeInterval(-AgentAccessConstants.approvalTimeout),
            expiresAt: expiresAt,
        )
    }

    /// An audit entry.
    static func auditEntry(
        kind: AgentAccessAuditKind = .credentialApproved,
        connectionName: String? = "Codex",
        query: AgentAccessQuery? = .domain("example.com"),
    ) -> AgentAccessAuditEntry {
        AgentAccessAuditEntry(
            id: UUID(),
            date: referenceDate,
            kind: kind,
            connectionFingerprint: fingerprint,
            connectionName: connectionName,
            query: query,
            cipherId: nil,
        )
    }

    /// An automatic approval rule.
    static func autoApproveRule(id: String = "rule-1") -> AgentAccessAutoApproveRule {
        AgentAccessAutoApproveRule(
            id: id,
            connectionFingerprint: fingerprint,
            connectionName: "Codex",
            query: .domain("example.com"),
            cipherId: "cipher-1",
            expiresAt: referenceDate.addingTimeInterval(600),
        )
    }

    /// A vault login that can answer a request.
    static func candidate(
        id: String = "cipher-1",
        name: String = "Example",
        username: String? = "user@example.com",
    ) -> AgentAccessCandidate {
        AgentAccessCandidate(id: id, name: name, username: username, uri: "https://example.com")
    }

    /// A paired agent.
    static func connection(
        fingerprint: String = fingerprint,
        name: String? = "Codex",
    ) -> AgentAccessConnection {
        AgentAccessConnection(
            fingerprint: fingerprint,
            name: name,
            pairedAt: referenceDate,
            lastConnectedAt: referenceDate.addingTimeInterval(60),
        )
    }

    /// A pairing token or code.
    static func pairing(
        kind: AgentAccessPairingKind = .psk,
        token: String = "token",
    ) -> AgentAccessPairing {
        AgentAccessPairing(
            kind: kind,
            token: token,
            name: "Codex",
            createdAt: referenceDate,
            expiresAt: referenceDate.addingTimeInterval(600),
        )
    }
}
