import Networking

/// A `RequestHandler` that applies default headers (user agent, client type & name, etc) to requests.
///
public final class DefaultHeadersRequestHandler: RequestHandler {
    // MARK: Properties

    /// The app's version number.
    let appVersion: String

    /// Builds the user agent string from app and device information.
    let userAgentBuilder: UserAgentBuilder

    // MARK: Initialization

    /// Initializes a `DefaultHeadersRequestHandler`.
    ///
    /// - Parameters:
    ///   - appVersion: The app's version number.
    ///   - userAgentBuilder: Builds the user agent string from app and device information.
    ///
    public init(appVersion: String, userAgentBuilder: UserAgentBuilder) {
        self.appVersion = appVersion
        self.userAgentBuilder = userAgentBuilder
    }

    // MARK: Request Handler

    public func handle(_ request: inout HTTPRequest) async throws -> HTTPRequest {
        request.headers["Bitwarden-Client-Name"] = Constants.clientType
        request.headers["Bitwarden-Client-Version"] = appVersion
        request.headers["Device-Type"] = String(Constants.deviceType)
        request.headers["User-Agent"] = userAgentBuilder.value

        return request
    }
}
