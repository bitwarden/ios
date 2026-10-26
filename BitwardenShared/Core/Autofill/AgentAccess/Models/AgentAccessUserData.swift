import Foundation

// MARK: - AgentAccessStoredConnection

/// A paired agent as persisted for the SDK. The transport state is opaque secret key material.
///
struct AgentAccessStoredConnection: Codable, Equatable {
    /// The 64 character lowercase hex identity fingerprint of the remote agent.
    var fingerprint: String

    /// The name the user gave the connection when pairing.
    var name: String?

    /// The Unix time in seconds the connection was first cached.
    var cachedAt: UInt64

    /// The Unix time in seconds of the last successful connection.
    var lastConnectedAt: UInt64

    /// The opaque transport state bytes owned by the SDK.
    var transportState: Data?
}

// MARK: - AgentAccessUserData

/// Everything Agent Access persists for one user, stored as a single keychain item.
///
struct AgentAccessUserData: Codable, Equatable {
    // MARK: Properties

    /// The identity key material owned by the SDK, as opaque bytes.
    var identity: Data?

    /// The 64 character hex fingerprint of `identity`.
    var identityFingerprint: String?

    /// The paired agents.
    var connections: [AgentAccessStoredConnection]

    /// Whether the user wants to receive agent requests on this device.
    var listeningEnabled: Bool

    /// The relay URL chosen by the user, if any.
    var relayURL: String?

    /// The audit log, newest first.
    var audit: [AgentAccessAuditEntry]

    // MARK: Initialization

    /// Initialize an `AgentAccessUserData`.
    ///
    /// - Parameters:
    ///   - identity: The identity key material owned by the SDK, as opaque bytes.
    ///   - identityFingerprint: The 64 character hex fingerprint of the identity.
    ///   - connections: The paired agents.
    ///   - listeningEnabled: Whether the user wants to receive agent requests on this device.
    ///   - relayURL: The relay URL chosen by the user, if any.
    ///   - audit: The audit log, newest first.
    ///
    init(
        identity: Data? = nil,
        identityFingerprint: String? = nil,
        connections: [AgentAccessStoredConnection] = [],
        listeningEnabled: Bool = false,
        relayURL: String? = nil,
        audit: [AgentAccessAuditEntry] = [],
    ) {
        self.identity = identity
        self.identityFingerprint = identityFingerprint
        self.connections = connections
        self.listeningEnabled = listeningEnabled
        self.relayURL = relayURL
        self.audit = audit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identity = try container.decodeIfPresent(Data.self, forKey: .identity)
        identityFingerprint = try container.decodeIfPresent(String.self, forKey: .identityFingerprint)
        connections = try container.decodeIfPresent([AgentAccessStoredConnection].self, forKey: .connections) ?? []
        listeningEnabled = try container.decodeIfPresent(Bool.self, forKey: .listeningEnabled) ?? false
        relayURL = try container.decodeIfPresent(String.self, forKey: .relayURL)
        audit = try container.decodeIfPresent([AgentAccessAuditEntry].self, forKey: .audit) ?? []
    }
}
