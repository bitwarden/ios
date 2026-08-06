import BitwardenSdk

// MARK: - StubServerCommunicationConfigClientProtocol

/// A stub implementation of `ServerCommunicationConfigClientProtocol`.
public final class StubServerCommunicationConfigClientProtocol: ServerCommunicationConfigClientProtocol {
    public init() {}

    public func acquireCookie(domain: String) async throws {
        // no-op
    }

    public func cookies(domain: String) async -> [BitwardenSdk.AcquiredCookie] {
        []
    }

    public func getConfig(domain: String) async throws -> BitwardenSdk.ServerCommunicationConfig {
        ServerCommunicationConfig(bootstrap: .direct)
    }

    public func getCookies(domain: String) async throws -> [BitwardenSdk.AcquiredCookie] {
        []
    }

    public func needsBootstrap(domain: String) async -> Bool {
        false
    }

    public func setCommunicationType(domain: String, request: BitwardenSdk.SetCommunicationTypeRequest) async throws {
        // no-op
    }

    public func setCommunicationTypeV2(request: BitwardenSdk.SetCommunicationTypeRequest) async throws {
        // no-op
    }
}
