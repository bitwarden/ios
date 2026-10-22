import AgentAccessSdk
import Foundation

// MARK: - AgentAccessSdkClient

/// A protocol for a thin wrapper around the Agent Access SDK `UserClient`.
///
protocol AgentAccessSdkClient: AnyObject { // sourcery: AutoMockable
    /// Closes the connection and releases the resources of the client.
    func close() async

    /// Connects to the relay and starts listening. Replaces any previous connection.
    func connect() async throws

    /// Returns the stable identity fingerprint (64 hex characters), creating the identity if needed.
    func getIdentityFingerprint() async throws -> String

    /// Creates a PSK pairing token.
    ///
    /// - Parameters:
    ///   - name: The name of the connection the token pairs.
    ///   - reusable: Whether the token can be used more than once.
    /// - Returns: The token.
    ///
    func getPskToken(name: String?, reusable: Bool) async throws -> String

    /// Creates a rendezvous pairing code.
    ///
    /// - Parameter name: The name of the connection the code pairs.
    /// - Returns: The code.
    ///
    func getRendezvousToken(name: String?) async throws -> String
}

// MARK: - AgentAccessSdkClientFactory

/// A protocol for a factory that creates `AgentAccessSdkClient`s.
///
protocol AgentAccessSdkClientFactory: AnyObject { // sourcery: AutoMockable
    /// Creates a client that is not connected yet.
    ///
    /// - Parameters:
    ///   - relayURL: The `ws://` or `wss://` URL of the relay.
    ///   - handler: The handler the client calls back into.
    /// - Returns: The client.
    ///
    func makeClient(relayURL: String, handler: AgentAccessSdkHandler) throws -> AgentAccessSdkClient
}

// MARK: - DefaultAgentAccessSdkClientFactory

/// The default implementation of `AgentAccessSdkClientFactory`.
///
final class DefaultAgentAccessSdkClientFactory: AgentAccessSdkClientFactory {
    func makeClient(relayURL: String, handler: AgentAccessSdkHandler) throws -> AgentAccessSdkClient {
        try DefaultAgentAccessSdkClient(relayURL: relayURL, handler: handler)
    }
}

// MARK: - DefaultAgentAccessSdkClient

/// The default implementation of `AgentAccessSdkClient`, backed by the Rust `UserClient`.
///
final class DefaultAgentAccessSdkClient: AgentAccessSdkClient, @unchecked Sendable {
    // MARK: Properties

    /// The callback object handed to the SDK. Kept so it lives as long as the client.
    private let callbacks: AgentAccessSdkCallbacks

    /// The SDK client.
    private let client: UserClient

    // MARK: Initialization

    /// Initialize a `DefaultAgentAccessSdkClient`.
    ///
    /// - Parameters:
    ///   - relayURL: The `ws://` or `wss://` URL of the relay.
    ///   - handler: The handler the client calls back into.
    ///
    init(relayURL: String, handler: AgentAccessSdkHandler) throws {
        let callbacks = AgentAccessSdkCallbacks(handler: handler)
        self.callbacks = callbacks
        do {
            client = try UserClient(
                relayUrl: relayURL,
                identityStorage: callbacks,
                connectionStorage: callbacks,
                handler: callbacks,
                fingerprintVerifier: callbacks,
                eventHandler: callbacks,
                auditLogger: callbacks,
                pskStorage: nil,
            )
        } catch {
            throw AgentAccessError.sdk(message: String(describing: error))
        }
    }

    // MARK: AgentAccessSdkClient

    func close() async {
        await client.close()
    }

    func connect() async throws {
        do {
            try await client.connect()
        } catch {
            throw AgentAccessError.sdk(message: String(describing: error))
        }
    }

    func getIdentityFingerprint() async throws -> String {
        // Loading the identity calls back into the app and blocks, so it must not run on a Swift
        // concurrency thread.
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().async {
                do {
                    try continuation.resume(returning: self.client.getIdentityFingerprint())
                } catch {
                    continuation.resume(throwing: AgentAccessError.sdk(message: String(describing: error)))
                }
            }
        }
    }

    func getPskToken(name: String?, reusable: Bool) async throws -> String {
        do {
            return try await client.getPskToken(name: name, reusable: reusable)
        } catch {
            throw AgentAccessError.sdk(message: String(describing: error))
        }
    }

    func getRendezvousToken(name: String?) async throws -> String {
        do {
            return try await client.getRendezvousToken(name: name)
        } catch {
            throw AgentAccessError.sdk(message: String(describing: error))
        }
    }
}
