import BitwardenKit
import BitwardenSdk
import Foundation
import Networking

/// A `RequestHandler` that handles whether the HTTP request needs SSO vendor cookie.
struct SSOCookieVendorRequestHandler: RequestHandler {
    // MARK: Properties

    /// The singleton for handling server communication bootstrap.
    private let serverCommunicationConfigClientSingleton: () -> ServerCommunicationConfigClientSingleton?

    // MARK: Init

    /// Initializes a `SSOCookieVendorRequestHandler`.
    /// - Parameters:
    ///   - serverCommunicationConfigClientSingleton: The singleton for handling server communication bootstrap.
    init(
        serverCommunicationConfigClientSingleton: @escaping () -> ServerCommunicationConfigClientSingleton?,
    ) {
        self.serverCommunicationConfigClientSingleton = serverCommunicationConfigClientSingleton
    }

    // MARK: Methods

    func handle(_ request: inout Networking.HTTPRequest) async throws -> Networking.HTTPRequest {
        guard let requestURLHost = request.url.host,
              let serverCommunicationConfigClientSingleton = serverCommunicationConfigClientSingleton()
        else {
            return request
        }

        let hostname = await serverCommunicationConfigClientSingleton.resolveHostname(hostname: requestURLHost)

        let serverCommunicationConfigClient = try await serverCommunicationConfigClientSingleton.client()
        let serverCommunicationConfig = try await serverCommunicationConfigClient.getConfig(hostname: hostname)
        guard case .ssoCookieVendor = serverCommunicationConfig.bootstrap else {
            return request
        }

        let cookies = await serverCommunicationConfigClient.cookies(hostname: hostname)
        guard !cookies.isEmpty else {
            return request
        }

        for cookie in cookies {
            let cookie = HTTPCookie(properties: [
                .domain: hostname,
                .name: cookie.name,
                .path: "/",
                .value: cookie.value,
            ])!
            for (field, value) in HTTPCookie.requestHeaderFields(with: [cookie]) {
                request.headers[field] = value
            }
        }

        return request
    }
}
