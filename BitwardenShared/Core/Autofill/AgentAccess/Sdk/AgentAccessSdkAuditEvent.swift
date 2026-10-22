import Foundation

// MARK: - AgentAccessSdkAuditEvent

/// A security relevant event emitted by the SDK client.
///
struct AgentAccessSdkAuditEvent: Equatable, Sendable {
    /// The kind of the event, one of the kinds the SDK reports.
    let kind: AgentAccessAuditKind

    /// The 64 character hex identity fingerprint of the remote agent.
    let remoteFingerprint: String

    /// The name of the remote agent, when the SDK knows it.
    let remoteName: String?

    /// The query of a credential event.
    let query: AgentAccessQuery?

    /// The vault item ID of an approved or denied credential event.
    let cipherId: String?
}
