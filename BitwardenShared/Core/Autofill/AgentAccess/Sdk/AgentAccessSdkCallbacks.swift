import AgentAccessSdk
import Foundation

// MARK: - AgentAccessSdkCallbacks

/// The object the SDK calls into. It converts SDK types to app types and forwards to the handler.
///
final class AgentAccessSdkCallbacks: @unchecked Sendable {
    // MARK: Properties

    /// The handler the callbacks are forwarded to.
    private let handler: AgentAccessSdkHandler

    // MARK: Initialization

    /// Initialize an `AgentAccessSdkCallbacks`.
    ///
    /// - Parameter handler: The handler the callbacks are forwarded to.
    ///
    init(handler: AgentAccessSdkHandler) {
        self.handler = handler
    }

    // MARK: Private Methods

    /// Converts an app connection to the SDK type.
    private func sdkConnection(_ connection: AgentAccessStoredConnection) -> FfiStoredConnection {
        FfiStoredConnection(
            fingerprint: connection.fingerprint,
            name: connection.name,
            cachedAt: connection.cachedAt,
            lastConnectedAt: connection.lastConnectedAt,
            transportState: connection.transportState,
        )
    }

    /// Converts an SDK connection to the app type.
    private func appConnection(_ connection: FfiStoredConnection) -> AgentAccessStoredConnection {
        AgentAccessStoredConnection(
            fingerprint: connection.fingerprint,
            name: connection.name,
            cachedAt: connection.cachedAt,
            lastConnectedAt: connection.lastConnectedAt,
            transportState: connection.transportState,
        )
    }

    /// Builds an audit event.
    private func auditEvent(
        _ kind: AgentAccessAuditKind,
        _ remoteFingerprint: String,
        remoteName: String? = nil,
        query: AgentAccessQuery? = nil,
        cipherId: String? = nil,
    ) -> AgentAccessSdkAuditEvent {
        AgentAccessSdkAuditEvent(
            kind: kind,
            remoteFingerprint: remoteFingerprint,
            remoteName: remoteName,
            query: query,
            cipherId: cipherId,
        )
    }

    /// Converts an SDK query to the app type.
    private func appQuery(_ query: FfiCredentialQuery) -> AgentAccessQuery {
        switch query {
        case let .domain(value):
            .domain(value)
        case let .id(value):
            .id(value)
        case let .search(value):
            .search(value)
        }
    }
}

// MARK: - IdentityStorage

extension AgentAccessSdkCallbacks: IdentityStorage {
    func loadIdentity() -> Data? {
        handler.loadIdentity()
    }

    func saveIdentity(identityBytes: Data) throws {
        do {
            try handler.saveIdentity(identityBytes)
        } catch {
            throw ClientError.SessionError(message: "Unable to save the identity")
        }
    }
}

// MARK: - ConnectionStorage

extension AgentAccessSdkCallbacks: ConnectionStorage {
    func get(fingerprintHex: String) -> FfiStoredConnection? {
        handler.connection(fingerprint: fingerprintHex).map(sdkConnection)
    }

    func save(connection: FfiStoredConnection) throws {
        do {
            try handler.saveConnection(appConnection(connection))
        } catch {
            throw ClientError.SessionError(message: "Unable to save the connection")
        }
    }

    func update(fingerprintHex: String, lastConnectedAt: UInt64) throws {
        do {
            try handler.updateConnection(fingerprint: fingerprintHex, lastConnectedAt: lastConnectedAt)
        } catch {
            throw ClientError.SessionError(message: "Unable to update the connection")
        }
    }

    func list() -> [FfiStoredConnection] {
        handler.listConnections().map(sdkConnection)
    }
}

// MARK: - CredentialProvider

extension AgentAccessSdkCallbacks: CredentialProvider {
    func handleCredentialRequest(query: FfiCredentialQuery, remoteFingerprint: String) -> FfiCredentialData? {
        guard let credential = handler.credential(for: appQuery(query), remoteFingerprint: remoteFingerprint) else {
            return nil
        }
        return FfiCredentialData(
            username: credential.username,
            password: credential.password,
            totp: nil,
            uri: nil,
            notes: nil,
            credentialId: credential.credentialId,
            domain: credential.domain,
        )
    }
}

// MARK: - FingerprintVerifier

extension AgentAccessSdkCallbacks: FingerprintVerifier {
    func verifyFingerprint(fingerprint: String, remoteIdentity: String?) -> Bool {
        handler.verifyFingerprint(code: fingerprint, remoteFingerprint: remoteIdentity)
    }
}

// MARK: - EventHandler

extension AgentAccessSdkCallbacks: EventHandler {
    func onEvent(event: FfiEvent) {
        let mapped: AgentAccessSdkEvent = switch event {
        case .connecting:
            .connecting
        case .connected:
            .connected
        case .listening:
            .listening
        case .disconnected:
            .disconnected
        case .reconnecting:
            .reconnecting
        case .reconnected:
            .reconnected
        case let .error(message, _):
            .error(message: message)
        default:
            .other
        }
        handler.handle(event: mapped)
    }
}

// MARK: - AuditLogger

extension AgentAccessSdkCallbacks: AuditLogger {
    func onAuditEvent(event: FfiAuditEvent) {
        let mapped = switch event {
        case let .connectionEstablished(remoteIdentity, remoteName, _):
            auditEvent(.connectionEstablished, remoteIdentity, remoteName: remoteName)
        case let .sessionRefreshed(remoteIdentity):
            auditEvent(.sessionRefreshed, remoteIdentity)
        case let .connectionRejected(remoteIdentity):
            auditEvent(.connectionRejected, remoteIdentity)
        case let .credentialRequested(query, remoteIdentity, _):
            auditEvent(.credentialRequested, remoteIdentity, query: appQuery(query))
        case let .credentialApproved(query, _, remoteIdentity, _, credentialId):
            auditEvent(.credentialApproved, remoteIdentity, query: appQuery(query), cipherId: credentialId)
        case let .credentialDenied(query, _, remoteIdentity, _, credentialId):
            auditEvent(.credentialDenied, remoteIdentity, query: appQuery(query), cipherId: credentialId)
        }
        handler.handle(auditEvent: mapped)
    }
}
