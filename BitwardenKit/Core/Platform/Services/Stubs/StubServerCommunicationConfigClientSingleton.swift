import BitwardenSdk

// MARK: - StubServerCommunicationConfigClientSingleton

/// A stub implementation for `ServerCommunicationConfigClientSingleton` to be used on apps that don't require it
/// but need the `HasServerCommunicationConfigClientSingleton`.
public struct StubServerCommunicationConfigClientSingleton: ServerCommunicationConfigClientSingleton {
    public init() {}

    public func client() async throws -> ServerCommunicationConfigClientProtocol {
        StubServerCommunicationConfigClientProtocol()
    }

    public func resolveHostname(hostname: String) async -> String {
        hostname
    }
}
