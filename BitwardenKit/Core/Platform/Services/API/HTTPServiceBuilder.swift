import Foundation
import Networking

/// A helper object to build `HTTPService`s with a common set of loggers and request and response handlers.
///
public class HTTPServiceBuilder {
    // MARK: Properties

    /// The underlying `HTTPClient` that performs the network request.
    private let client: HTTPClient

    /// A `RequestHandler` that applies default headers (user agent, client type & name, etc) to requests.
    private let defaultHeadersRequestHandler: DefaultHeadersRequestHandler

    /// A `RequestHandler` that applies the `Device-Identifier` header to requests.
    private let deviceIdentifierRequestHandler: DeviceIdentifierRequestHandler

    /// The loggers used to log HTTP requests and responses.
    private let loggers: [HTTPLogger]

    /// A `ResponseHandler` that validates that HTTP responses contain successful (2XX) HTTP status
    /// codes or tries to parse the error otherwise.
    private let responseValidationHandler = ResponseValidationHandler()

    /// A `RequestHandler` that handles whether the HTTP request needs SSO vendor cookie.
    private let ssoCookieVendorRequestHandler: RequestHandler

    /// A `ResponseHandler` that handles whether the HTTP response needs SSO cookie refresh.
    private let ssoCookieVendorResponseHandler: ResponseHandler

    // MARK: Initialization

    /// Initialize an `HTTPServiceBuilder`.
    ///
    /// - Parameters:
    ///   - client: The underlying `HTTPClient` that performs the network request.
    ///   - defaultHeadersRequestHandler: A `RequestHandler` that applies default headers
    ///     (user agent, client type & name, etc) to requests.
    ///   - deviceIdentifierRequestHandler: A `RequestHandler` that applies the `Device-Identifier`
    ///     header to requests, for services built with `includeDeviceIdentifier` enabled.
    ///   - loggers: The loggers used to log HTTP requests and responses.
    ///   - ssoCookieVendorRequestHandler: A `RequestHandler` that handles whether the HTTP request
    ///   needs SSO vendor cookie.
    ///   - ssoCookieVendorResponseHandler: A `ResponseHandler` that handles whether the HTTP response
    ///    needs SSO cookie refresh.
    ///
    public init(
        client: HTTPClient,
        defaultHeadersRequestHandler: DefaultHeadersRequestHandler,
        deviceIdentifierRequestHandler: DeviceIdentifierRequestHandler,
        loggers: [HTTPLogger],
        ssoCookieVendorRequestHandler: RequestHandler,
        ssoCookieVendorResponseHandler: ResponseHandler,
    ) {
        self.client = client
        self.defaultHeadersRequestHandler = defaultHeadersRequestHandler
        self.deviceIdentifierRequestHandler = deviceIdentifierRequestHandler
        self.loggers = loggers
        self.ssoCookieVendorRequestHandler = ssoCookieVendorRequestHandler
        self.ssoCookieVendorResponseHandler = ssoCookieVendorResponseHandler
    }

    // MARK: Methods

    /// Builds an `HTTPService`.
    ///
    /// - Parameters:
    ///   - baseURLGetter: A getter function for dynamically retrieving the base url against which
    ///     requests are resolved.
    ///   - tokenProvider: An object used to get an access token and refresh it when necessary.
    ///   - includeDeviceIdentifier: Whether the `Device-Identifier` header should be applied to
    ///     requests. This should only be enabled for services whose requests target Bitwarden hosts.
    ///     Defaults to `false`.
    /// - Returns: An `HTTPService` with common loggers and handlers applied.
    ///
    public func makeService(
        baseURLGetter: @escaping @Sendable () -> URL,
        tokenProvider: TokenProvider? = nil,
        includeDeviceIdentifier: Bool = false,
    ) -> HTTPService {
        var requestHandlers: [RequestHandler] = [
            defaultHeadersRequestHandler,
            ssoCookieVendorRequestHandler,
        ]
        if includeDeviceIdentifier {
            requestHandlers.append(deviceIdentifierRequestHandler)
        }

        return HTTPService(
            baseURLGetter: baseURLGetter,
            client: client,
            loggers: loggers,
            requestHandlers: requestHandlers,
            responseHandlers: [
                ssoCookieVendorResponseHandler, // Order matters here, DO NOT invert with `responseValidationHandler`.
                responseValidationHandler,
            ],
            tokenProvider: tokenProvider,
        )
    }
}
