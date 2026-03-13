import BitwardenSdk

// MARK: - StubServerCommunicationConfigClientProtocol

/// A stub implementation of `ServerCommunicationConfigClientProtocol`.
public final class StubServerCommunicationConfigClientProtocol: ServerCommunicationConfigClientProtocol {
    public init() {}

    public func acquireCookie(hostname: String) async throws {
        // no-op
    }

    public func cookies(hostname: String) async -> [BitwardenSdk.AcquiredCookie] {
        []
    }

    public func getConfig(hostname: String) async throws -> BitwardenSdk.ServerCommunicationConfig {
        ServerCommunicationConfig(bootstrap: .direct)
    }

    public func needsBootstrap(hostname: String) async -> Bool {
        false
    }

    public func setCommunicationType(hostname: String, config: BitwardenSdk.ServerCommunicationConfig) async throws {
        // no-op
    }
}
