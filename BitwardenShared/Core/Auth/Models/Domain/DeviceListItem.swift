import BitwardenKit
import Foundation

// MARK: - DeviceListItem

/// A UI-friendly model representing a device in the device management list.
///
struct DeviceListItem: Equatable, Identifiable, Sendable {
    // MARK: Properties

    /// The activity status of the device.
    let activityStatus: DeviceActivityStatus

    /// The type of the device.
    let deviceType: DeviceType

    /// The display name of the device.
    let displayName: String

    /// The date of the first login on this device.
    let firstLogin: Date

    /// Whether the device has a pending login request.
    var hasPendingRequest: Bool { pendingRequest != nil }

    /// The server-assigned UUID that uniquely identifies this device record across all users.
    let id: String

    /// The client-generated UUID embedded in the app on this device, used for push notifications
    /// and device recognition.
    let identifier: String

    /// Whether this is the current session's device.
    var isCurrentSession: Bool

    /// Whether the device is trusted.
    let isTrusted: Bool

    /// The date of the last activity on this device.
    let lastActivityDate: Date?

    /// The most recent pending login request for this device, if any.
    var pendingRequest: LoginRequest?
}

// MARK: - DeviceListItem Extension

extension DeviceListItem {
    // MARK: Initialization

    /// Initializes a `DeviceListItem` from a `DeviceResponse`.
    ///
    /// - Parameters:
    ///   - device: The device response from the API.
    ///   - timeProvider: The time provider to use for calculating the activity status.
    ///
    init(
        device: DeviceResponse,
        timeProvider: TimeProvider,
    ) {
        activityStatus = DeviceActivityStatus(from: device.lastActivityDate, timeProvider: timeProvider)
        deviceType = device.type
        displayName = device.type.displayName
        firstLogin = device.creationDate
        id = device.id
        identifier = device.identifier
        isCurrentSession = false
        isTrusted = device.isTrusted
        lastActivityDate = device.lastActivityDate
        pendingRequest = nil
    }
}
