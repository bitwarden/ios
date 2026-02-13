import BitwardenKit
import BitwardenSdk
import Networking

/// A `ResponseHandler` that handles whether the HTTP response needs SSO cookie refresh.
struct SSOCookieVendorResponseHandler: ResponseHandler {
    // MARK: Properties

    /// The service that handles common client functionality such as encryption and decryption.
    private let serverCommunicationConfigClientSingleton: ServerCommunicationConfigClientSingleton

    // MARK: Init

    /// Initializes a `SSOCookieVendorRequestHandler`.
    /// - Parameter clientService: The service that handles common client functionality such as encryption and decryption.
    init(serverCommunicationConfigClientSingleton: ServerCommunicationConfigClientSingleton) {
        self.serverCommunicationConfigClientSingleton = serverCommunicationConfigClientSingleton
    }

    func handle(_ response: inout Networking.HTTPResponse) async throws -> Networking.HTTPResponse {
        guard response.statusCode == 302,
              let hostname = response.url.host,
              let serverCommunicationConfigClient = try? await serverCommunicationConfigClientSingleton.client(),
              await serverCommunicationConfigClient.needsBootstrap(hostname: hostname) else {
            return response
        }

        try await serverCommunicationConfigClient.acquireCookie(hostname: hostname)

        return response
    }
}
