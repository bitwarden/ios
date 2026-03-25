import BitwardenKit
import Foundation
import Networking

// MARK: - DeviceResponse

/// A data structure representing a device response from the API.
///
public struct DeviceResponse: JSONResponse, Equatable, Sendable, Identifiable, Hashable {
    public static let decoder = JSONDecoder.defaultDecoder

    // MARK: Properties

    /// The unique identifier of the device.
    public let id: String

    /// The name of the device.
    let name: String?

    /// The unique identifier for this device instance.
    let identifier: String

    /// The numeric type of the device (maps to DeviceType).
    let type: Int

    /// The date the device was first registered.
    let creationDate: Date

    /// Whether the device is trusted.
    let isTrusted: Bool

    /// The date of the last activity on this device.
    let lastActivityDate: Date?
}
