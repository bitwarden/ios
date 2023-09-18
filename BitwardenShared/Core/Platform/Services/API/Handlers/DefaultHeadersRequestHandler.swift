import Networking
import UIKit

/// A `RequestHandler` that applies default headers (user agent, client type & name, etc) to requests.
///
class DefaultHeadersRequestHandler: RequestHandler {
    // MARK: Properties

    /// The app's name.
    let appName: String

    /// The app's version number.
    let appVersion: String

    /// The app's build number.
    let buildNumber: String

    /// A `SystemDevice` instance used to get device details.
    let systemDevice: SystemDevice

    // MARK: Initialization

    /// Initializes a `DefaultHeadersRequestHandler`.
    ///
    /// - Parameters:
    ///   - appName: The app's name.
    ///   - appVersion: The app's version number.
    ///   - buildNumber: The app's build number.
    ///   - systemDevice: A `SystemDevice` instance used to get device details.
    ///
    init(
        appName: String,
        appVersion: String,
        buildNumber: String,
        systemDevice: SystemDevice
    ) {
        self.appName = appName
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.systemDevice = systemDevice
    }

    // MARK: Request Handler

    func handle(_ request: inout HTTPRequest) async throws -> HTTPRequest {
        let osVersion = systemDevice.systemVersion
        let systemName = systemDevice.systemName
        let model = systemDevice.model

        request.headers["Bitwarden-Client-Name"] = Constants.clientType
        request.headers["Bitwarden-Client-Version"] = appVersion
        request.headers["Device-Type"] = String(Constants.deviceType)
        request.headers["User-Agent"] = "\(appName)/\(appVersion) (\(systemName) \(osVersion); Model \(model))"

        return request
    }
}
