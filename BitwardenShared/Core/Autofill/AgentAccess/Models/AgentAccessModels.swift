// swiftlint:disable:this file_name

import Foundation

// MARK: - AgentAccessConstants

enum AgentAccessConstants {
    static let defaultRelayURL = "wss://ap.lesspassword.dev"
    static let approvalTimeout: TimeInterval = 110
    static let autoApproveDurationsMinutes = [1, 5, 10, 15, 30, 60]
    static let defaultAutoApproveMinutes = 10
    static let maxAuditEntries = 200
    static let pskPairingLifetime: TimeInterval = 600
    static let rendezvousPairingLifetime: TimeInterval = 300
    static let debugRelayURLEnvironmentKey = "AGENT_ACCESS_RELAY_URL"
    static let debugDumpEnvironmentKey = "AGENT_ACCESS_DEBUG_DUMP"
    static let debugAutoPskNameEnvironmentKey = "AGENT_ACCESS_DEBUG_AUTO_PSK_NAME"
}

// MARK: - AgentAccessQuery

/// What the agent asked for.
enum AgentAccessQuery: Codable, Equatable, Sendable {
    case domain(String)
    case id(String)
    case search(String)

    /// The raw value for display and auditing.
    var displayValue: String {
        switch self {
        case let .domain(value), let .id(value), let .search(value):
            value
        }
    }

    /// A stable key identifying an identical query, used for auto-approve matching.
    var matchKey: String {
        switch self {
        case let .domain(value):
            "domain:\(value.lowercased())"
        case let .id(value):
            "id:\(value)"
        case let .search(value):
            "search:\(value.lowercased())"
        }
    }
}

// MARK: - AgentAccessConnection

/// A paired agent.
struct AgentAccessConnection: Codable, Equatable, Identifiable, Sendable {
    /// 64 character lowercase hex identity fingerprint of the remote agent.
    let fingerprint: String

    /// The name the user gave the connection when pairing.
    var name: String?

    let pairedAt: Date

    var lastConnectedAt: Date

    var id: String { fingerprint }

    var displayName: String {
        if let name, !name.isEmpty { return name }
        return String(fingerprint.prefix(8))
    }
}

// MARK: - Pairing

enum AgentAccessPairingKind: Equatable, Sendable {
    /// A one time pre-shared key token ("<64 hex>_<64 hex>"), shown as text and QR.
    case psk

    /// A rendezvous code ("ABC-DEF-GHI") typed into the agent; needs fingerprint comparison.
    case rendezvous
}

struct AgentAccessPairing: Equatable, Sendable {
    let kind: AgentAccessPairingKind

    /// The PSK token or the rendezvous code.
    let token: String

    /// The connection name chosen by the user.
    let name: String

    let createdAt: Date

    let expiresAt: Date
}

struct AgentAccessFingerprintVerification: Equatable, Identifiable, Sendable {
    let id: String

    /// The 6 character hex handshake fingerprint the agent also displays.
    let code: String

    /// The 64 character hex identity fingerprint of the agent being paired.
    let remoteFingerprint: String
}

enum AgentAccessPairingEvent: Equatable, Sendable {
    case waitingForAgent
    case verifyFingerprint(AgentAccessFingerprintVerification)
    case paired(AgentAccessConnection)
    case rejected
    case failed(message: String)
}

// MARK: - Status

enum AgentAccessConnectionStatus: Equatable, Sendable {
    /// Feature off, or the user has not enabled listening.
    case disabled
    case connecting
    case listening
    case reconnecting
    case failed(message: String)
}

// MARK: - Approval

struct AgentAccessApprovalRequest: Equatable, Identifiable, Sendable {
    /// A local UUID. The SDK callback does not expose the protocol request id.
    let id: String

    let userId: String

    let connectionFingerprint: String

    let connectionName: String

    let query: AgentAccessQuery

    let receivedAt: Date

    /// `receivedAt + AgentAccessConstants.approvalTimeout`.
    let expiresAt: Date
}

struct AgentAccessCandidate: Equatable, Identifiable, Sendable {
    /// The vault item (cipher) id.
    let id: String

    let name: String

    let username: String?

    let uri: String?
}

enum AgentAccessDecision: Equatable, Sendable {
    /// Approve with this vault item. `autoApproveMinutes` (one of `autoApproveDurationsMinutes`)
    /// remembers the decision for an identical query from the same connection.
    case approve(cipherId: String, autoApproveMinutes: Int?)

    case deny
}

struct AgentAccessAutoApproveRule: Equatable, Identifiable, Sendable {
    let id: String
    let connectionFingerprint: String
    let connectionName: String
    let query: AgentAccessQuery
    let cipherId: String
    let expiresAt: Date
}

// MARK: - Audit

enum AgentAccessAuditKind: String, Codable, Equatable, Sendable {
    case connectionEstablished
    case sessionRefreshed
    case connectionRejected
    case connectionRevoked
    case credentialRequested
    case credentialApproved
    case credentialAutoApproved
    case credentialDenied
    case credentialExpired
}

/// An audit log entry. Never contains credential values.
struct AgentAccessAuditEntry: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let date: Date
    let kind: AgentAccessAuditKind
    let connectionFingerprint: String
    let connectionName: String?
    let query: AgentAccessQuery?
    let cipherId: String?
}

// MARK: - Errors

enum AgentAccessError: Error, Equatable {
    case featureDisabled
    case noActiveAccount
    case notListening
    case requestNotFound
    case requestExpired
    case cipherNotFound
    case invalidRelayURL
    case sdk(message: String)
}
