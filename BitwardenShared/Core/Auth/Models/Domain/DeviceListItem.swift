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
    var hasPendingRequest: Bool

    /// The unique identifier of the device.
    let id: String

    /// The unique identifier for this device instance.
    let identifier: String

    /// Whether this is the current session's device.
    var isCurrentSession: Bool

    /// Whether the device is trusted.
    let isTrusted: Bool

    /// The date of the last activity on this device.
    let lastActivityDate: Date?

    /// The most recent pending login request for this device, if any.
    var pendingRequest: LoginRequest?

    // MARK: Initialization

    /// Initializes a `DeviceListItem` with all properties.
    ///
    /// - Parameters:
    ///   - activityStatus: The activity status of the device.
    ///   - deviceType: The type of the device.
    ///   - displayName: The display name of the device.
    ///   - firstLogin: The date of the first login on this device.
    ///   - hasPendingRequest: Whether the device has a pending login request.
    ///   - id: The unique identifier of the device.
    ///   - identifier: The unique identifier for this device instance.
    ///   - isCurrentSession: Whether this is the current session's device.
    ///   - isTrusted: Whether the device is trusted.
    ///   - lastActivityDate: The date of the last activity on this device.
    ///   - pendingRequest: The most recent pending login request for this device.
    ///
    init(
        activityStatus: DeviceActivityStatus,
        deviceType: DeviceType,
        displayName: String,
        firstLogin: Date,
        hasPendingRequest: Bool,
        id: String,
        identifier: String,
        isCurrentSession: Bool,
        isTrusted: Bool,
        lastActivityDate: Date?,
        pendingRequest: LoginRequest?,
    ) {
        self.activityStatus = activityStatus
        self.deviceType = deviceType
        self.displayName = displayName
        self.firstLogin = firstLogin
        self.hasPendingRequest = hasPendingRequest
        self.id = id
        self.identifier = identifier
        self.isCurrentSession = isCurrentSession
        self.isTrusted = isTrusted
        self.lastActivityDate = lastActivityDate
        self.pendingRequest = pendingRequest
    }

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
        let type = DeviceType(device.type)
        activityStatus = DeviceActivityStatus(from: device.lastActivityDate, timeProvider: timeProvider)
        deviceType = type
        displayName = type.displayName
        firstLogin = device.creationDate
        hasPendingRequest = false
        id = device.id
        identifier = device.identifier
        isCurrentSession = false
        isTrusted = device.isTrusted
        lastActivityDate = device.lastActivityDate
        pendingRequest = nil
    }
}
