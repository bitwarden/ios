import Networking

/// A `RequestHandler` that applies the `Device-Identifier` header, containing the app's ID, to
/// requests. The server uses this to identify the device making unauthenticated requests (e.g. to
/// scope new device verification and two-step login codes to the device that requested them).
///
/// This should only be applied to services whose requests target Bitwarden hosts.
///
public final class DeviceIdentifierRequestHandler: RequestHandler {
    // MARK: Constants

    /// The name of the header containing the device identifier.
    static let headerName = "Device-Identifier"

    // MARK: Properties

    /// The service used by the application to manage the app's ID.
    let appIDService: AppIDService

    // MARK: Initialization

    /// Initializes a `DeviceIdentifierRequestHandler`.
    ///
    /// - Parameter appIDService: The service used by the application to manage the app's ID.
    ///
    public init(appIDService: AppIDService) {
        self.appIDService = appIDService
    }

    // MARK: Request Handler

    public func handle(_ request: inout HTTPRequest) async throws -> HTTPRequest {
        request.headers[Self.headerName] = await appIDService.getOrCreateAppID()
        return request
    }
}
