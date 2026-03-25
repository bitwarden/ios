import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - DeviceListItem

/// A UI-friendly model representing a device in the device management list.
///
struct DeviceListItem: Equatable, Identifiable, Sendable {
    // MARK: Properties

    /// The unique identifier of the device.
    let id: String

    /// The unique identifier for this device instance.
    let identifier: String

    /// The display name of the device.
    let displayName: String

    /// The type of the device.
    let deviceType: DeviceType

    /// Whether the device is trusted.
    let isTrusted: Bool

    /// Whether this is the current session's device.
    var isCurrentSession: Bool

    /// Whether the device has a pending login request.
    var hasPendingRequest: Bool

    /// The activity status of the device.
    let activityStatus: DeviceActivityStatus

    /// The date of the first login on this device.
    let firstLogin: Date

    /// The date of the last activity on this device.
    let lastActivityDate: Date?

    /// The most recent pending login request for this device, if any.
    var pendingRequest: LoginRequest?

    // MARK: Initialization

    /// Initializes a `DeviceListItem` with all properties.
    ///
    /// - Parameters:
    ///   - id: The unique identifier of the device.
    ///   - identifier: The unique identifier for this device instance.
    ///   - displayName: The display name of the device.
    ///   - deviceType: The type of the device.
    ///   - isTrusted: Whether the device is trusted.
    ///   - isCurrentSession: Whether this is the current session's device.
    ///   - hasPendingRequest: Whether the device has a pending login request.
    ///   - activityStatus: The activity status of the device.
    ///   - firstLogin: The date of the first login on this device.
    ///   - lastActivityDate: The date of the last activity on this device.
    ///   - pendingRequest: The most recent pending login request for this device.
    ///
    init(
        id: String,
        identifier: String,
        displayName: String,
        deviceType: DeviceType,
        isTrusted: Bool,
        isCurrentSession: Bool,
        hasPendingRequest: Bool,
        activityStatus: DeviceActivityStatus,
        firstLogin: Date,
        lastActivityDate: Date?,
        pendingRequest: LoginRequest?,
    ) {
        self.id = id
        self.identifier = identifier
        self.displayName = displayName
        self.deviceType = deviceType
        self.isTrusted = isTrusted
        self.isCurrentSession = isCurrentSession
        self.hasPendingRequest = hasPendingRequest
        self.activityStatus = activityStatus
        self.firstLogin = firstLogin
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
        id = device.id
        identifier = device.identifier
        displayName = type.displayName
        deviceType = type
        isTrusted = device.isTrusted
        isCurrentSession = false
        hasPendingRequest = false
        activityStatus = DeviceActivityStatus(from: device.lastActivityDate, timeProvider: timeProvider)
        firstLogin = device.creationDate
        lastActivityDate = device.lastActivityDate
        pendingRequest = nil
    }
}
