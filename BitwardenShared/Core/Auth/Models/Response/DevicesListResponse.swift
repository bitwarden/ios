import Foundation
import Networking

// MARK: - DevicesListResponse

/// The response returned from the API when requesting the list of devices.
///
struct DevicesListResponse: JSONResponse {
    static let decoder = JSONDecoder.defaultDecoder

    // MARK: Properties

    /// The list of devices returned by the API request.
    let data: [DeviceResponse]
}
