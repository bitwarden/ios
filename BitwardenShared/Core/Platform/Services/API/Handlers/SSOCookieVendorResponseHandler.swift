import BitwardenKit
import BitwardenResources
import BitwardenSdk
import Foundation
import Networking

/// A `ResponseHandler` that handles whether the HTTP response needs SSO cookie refresh.
struct SSOCookieVendorResponseHandler: ResponseHandler {
    // MARK: Properties

    /// The service used by the application to manage the environment settings.
    private let environmentService: EnvironmentService

    /// The singleton for handling server communication bootstrap.
    private let serverCommunicationConfigClientSingleton: () -> ServerCommunicationConfigClientSingleton?

    // MARK: Init

    /// Initializes a `SSOCookieVendorRequestHandler`.
    /// - Parameters:
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - serverCommunicationConfigClientSingleton: The singleton for handling server communication bootstrap.
    init(
        environmentService: EnvironmentService,
        serverCommunicationConfigClientSingleton: @escaping () -> ServerCommunicationConfigClientSingleton?,
    ) {
        self.environmentService = environmentService
        self.serverCommunicationConfigClientSingleton = serverCommunicationConfigClientSingleton
    }

    func handle(
        _ response: inout HTTPResponse,
        for request: HTTPRequest,
        retryWith: ((HTTPRequest) async throws -> HTTPResponse)?,
    ) async throws -> HTTPResponse {
        guard response.statusCode == 302 else {
            return response
        }

        guard let hostname = environmentService.webVaultURL.host,
              let serverCommunicationConfigClient = try? await serverCommunicationConfigClientSingleton()?.client(),
              await serverCommunicationConfigClient.needsBootstrap(hostname: hostname)
        else {
            // Manually perform the 302 redirection, if needed/possible.
            guard let retryWith,
                  let location = response.headers["Location"],
                  let redirectURL = URL(string: location)
            else {
                return response
            }

            var redirectRequest = request
            redirectRequest.url = redirectURL
            return try await retryWith(redirectRequest)
        }

        do {
            try await serverCommunicationConfigClient.acquireCookie(hostname: hostname)
        } catch BitwardenSdk.BitwardenError.AcquireCookie(.Cancelled(_)) {
            // no-op, just continue to throw the error to try again.
        }

        throw ServerError.error(
            errorResponse: ErrorResponseModel(
                validationErrors: nil,
                message: Localizations.tryAgain,
            ),
        )
    }
}
