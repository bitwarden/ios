import Networking

// MARK: - CurrentDeviceRequest

/// A request for retrieving the current device by its app identifier.
///
struct CurrentDeviceRequest: Request {
    typealias Response = DeviceResponse

    // MARK: Properties

    /// The unique app identifier for this device.
    let appId: String

    var method: HTTPMethod { .get }

    var path: String { "/devices/identifier/\(appId)" }
}
