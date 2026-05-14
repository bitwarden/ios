import Foundation

@testable import BitwardenShared

extension DeviceListItem {
    static func fixture(
        activityStatus: DeviceActivityStatus = .today,
        deviceType: DeviceType = .iOS,
        displayName: String = "Mobile - iOS",
        firstLogin: Date = Date(timeIntervalSince1970: 1_704_067_200),
        hasPendingRequest: Bool = false,
        id: String = "device-id-1",
        identifier: String = "device-identifier-1",
        isCurrentSession: Bool = false,
        isTrusted: Bool = true,
        lastActivityDate: Date? = Date(timeIntervalSince1970: 1_718_452_200),
        pendingRequest: LoginRequest? = nil,
    ) -> DeviceListItem {
        DeviceListItem(
            activityStatus: activityStatus,
            deviceType: deviceType,
            displayName: displayName,
            firstLogin: firstLogin,
            hasPendingRequest: hasPendingRequest,
            id: id,
            identifier: identifier,
            isCurrentSession: isCurrentSession,
            isTrusted: isTrusted,
            lastActivityDate: lastActivityDate,
            pendingRequest: pendingRequest,
        )
    }
}
