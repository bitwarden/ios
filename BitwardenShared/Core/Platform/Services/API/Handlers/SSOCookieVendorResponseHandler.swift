import BitwardenKit
import BitwardenResources
import BitwardenSdk
import Foundation
import Networking

/// A `ResponseHandler` that handles whether the HTTP response needs SSO cookie refresh.
struct SSOCookieVendorResponseHandler: ResponseHandler {
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

    func handle(
        _ response: inout HTTPResponse,
        for request: HTTPRequest,
        retryWith: ((HTTPRequest) async throws -> HTTPResponse)?,
    ) async throws -> HTTPResponse {
        guard response.statusCode == 302 else {
            return response
        }

        guard let requestURLHost = request.url.host,
              let serverCommunicationConfigClientSingleton = serverCommunicationConfigClientSingleton() else {
            return try await manuallyHandle302Redirect(&response, for: request, retryWith: retryWith)
        }

        let hostname = await serverCommunicationConfigClientSingleton.resolveHostname(hostname: requestURLHost)

        guard let serverCommunicationConfigClient = try? await serverCommunicationConfigClientSingleton.client(),
              await serverCommunicationConfigClient.needsBootstrap(hostname: hostname)
        else {
            return try await manuallyHandle302Redirect(&response, for: request, retryWith: retryWith)
        }

        do {
            try await serverCommunicationConfigClient.acquireCookie(hostname: hostname)
        } catch BitwardenSdk.BitwardenError.AcquireCookie(.Cancelled(_)) {
            // no-op, just continue to throw the error to try again.
        }

        throw ServerError.error(
            errorResponse: ErrorResponseModel(
                validationErrors: nil,
                message: Localizations.yourRequestWasInterruptedBecauseTheAppNeededToReAuthenticatePleaseTryAgain,
            ),
        )
    }

    // MARK: Private methods

    /// Manually handles redirecting the 302.
    /// - Parameters:
    ///   - response: The `HTTPResponse` that was received by the `HTTPClient`.
    ///   - request: The original `HTTPRequest` that produced this response.
    ///   - retryWith: An optional closure that re-sends a request through the full `HTTPService`
    ///     pipeline (request handlers, logging, token refresh, and subsequent response handlers).
    ///     Pass `nil` when redirect-following has already been attempted for this call chain, to
    ///     prevent infinite recursion. Handlers that do not need to re-send a request can ignore
    ///     this parameter.
    /// - Returns: The original or modified `HTTPResponse`.
    private func manuallyHandle302Redirect(
        _ response: inout HTTPResponse,
        for request: HTTPRequest,
        retryWith: ((HTTPRequest) async throws -> HTTPResponse)?,
    ) async throws -> HTTPResponse {
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
}
