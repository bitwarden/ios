import BitwardenKit
import BitwardenSdk
import Foundation
import Networking

/// A `RequestHandler` that handles whether the HTTP request needs SSO vendor cookie.
struct SSOCookieVendorRequestHandler: RequestHandler {
    // MARK: Properties

    /// The service that handles common client functionality such as encryption and decryption.
    private let serverCommunicationConfigClientSingleton: ServerCommunicationConfigClientSingleton

    // MARK: Init

    /// Initializes a `SSOCookieVendorRequestHandler`.
    /// - Parameter clientService: The service that handles common client functionality such as encryption and decryption.
    init(serverCommunicationConfigClientSingleton: ServerCommunicationConfigClientSingleton) {
        self.serverCommunicationConfigClientSingleton = serverCommunicationConfigClientSingleton
    }

    // MARK: Methods

    func handle(_ request: inout Networking.HTTPRequest) async throws -> Networking.HTTPRequest {
        guard let hostname = request.url.host,
              let serverCommunicationConfigClient = try? await serverCommunicationConfigClientSingleton.client(),
              await serverCommunicationConfigClient.needsBootstrap(hostname: hostname) else {
            return request
        }

        let cookies = await serverCommunicationConfigClient.cookies(hostname: hostname)
        guard !cookies.isEmpty else {
            return request
        }

        for cookie in cookies {
            let cookie = HTTPCookie(properties: [
                .name: cookie.name,
                .value: cookie.value,
            ])!
            for (field, value) in HTTPCookie.requestHeaderFields(with: [cookie]) {
                request.headers[field] = value
            }
        }

        return request
    }
}
