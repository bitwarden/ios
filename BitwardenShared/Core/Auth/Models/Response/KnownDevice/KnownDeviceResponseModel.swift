import Foundation
import Networking

// MARK: - KnownDeviceResponse

/// An object containing a value defining if this device has previously logged into this account or not.
struct KnownDeviceResponseModel: JSONResponse {
    static var decoder = JSONDecoder()

    // MARK: Properties

    /// A flag indicating if this device is known or not.
    var isKnownDevice: Bool

    // MARK: Initialization

    /// Creates a new `KnownDeviceResponseModel` instance.
    ///
    /// - Parameter isKnownDevice: A flag indicating if this device is known or not.
    init(isKnownDevice: Bool) {
        self.isKnownDevice = isKnownDevice
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        isKnownDevice = try container.decode(Bool.self)
    }
}
