import BitwardenSdk
import TestHelpers

@testable import BitwardenShared

final class MockServerCommunicationConfigClientSingleton: ServerCommunicationConfigClientSingleton {
    var clientResult: Result<ServerCommunicationConfigClientProtocol, Error> =
        .failure(BitwardenTestError.example)

    var resolveHostnameReceivedHostname: String?
    var resolveHostnameResult: String?

    func client() async throws -> ServerCommunicationConfigClientProtocol {
        try clientResult.get()
    }

    func resolveHostname(hostname: String) async -> String {
        resolveHostnameReceivedHostname = hostname
        return resolveHostnameResult ?? hostname
    }
}
