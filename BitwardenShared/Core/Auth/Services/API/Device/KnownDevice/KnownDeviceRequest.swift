import Foundation
import Networking

// MARK: - KnownDeviceRequest

/// A request for determining if this is a known device.
struct KnownDeviceRequest: Request {
    typealias Response = KnownDeviceResponseModel

    let path = "/devices/knowndevice"

    let headers: [String: String]

    /// Creates a new `KnownDeviceRequest` instance.
    ///
    /// - Parameters:
    ///   - email: The email address for the user.
    ///   - deviceIdentifier: The unique identifier for this device.
    ///
    init(email: String, deviceIdentifier: String) {
        let emailData = Data(email.utf8)
        let emailEncoded = emailData.base64EncodedString().urlEncoded()
        headers = [
            "X-Request-Email": emailEncoded,
            "X-Device-Identifier": deviceIdentifier,
        ]
    }
}
