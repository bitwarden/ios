import BitwardenSdk
import BitwardenSdkMocks
import TestHelpers

@testable import BitwardenKit

public final class MockServerCommunicationConfigClientSingleton: ServerCommunicationConfigClientSingleton {
    public var clientResult: Result<ServerCommunicationConfigClientProtocol, Error> =
        .success(MockServerCommunicationConfigClientProtocol.withDefaults())

    public var resolveHostnameReceivedHostname: String?
    public var resolveHostnameResult: String?

    public init() {}

    public func client() async throws -> ServerCommunicationConfigClientProtocol {
        try clientResult.get()
    }

    public func resolveHostname(hostname: String) async -> String {
        resolveHostnameReceivedHostname = hostname
        return resolveHostnameResult ?? hostname
    }
}
