import BitwardenKitMocks
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - DeviceListItemTests

struct DeviceListItemTests {
    // MARK: Properties

    let timeProvider = MockTimeProvider(.mockTime(Date(timeIntervalSince1970: 1_718_452_200)))

    // MARK: Tests

    /// `init(device:timeProvider:)` maps every property from the `DeviceResponse`.
    @Test
    func init_device() {
        let device = DeviceResponse.fixture(
            creationDate: Date(timeIntervalSince1970: 1_704_067_200),
            id: "device-id-2",
            identifier: "device-identifier-2",
            isTrusted: false,
            lastActivityDate: Date(timeIntervalSince1970: 1_718_452_200),
            type: .chromeExtension,
        )

        let subject = DeviceListItem(device: device, timeProvider: timeProvider)

        #expect(subject.deviceType == .chromeExtension)
        #expect(subject.displayName == device.type.displayName)
        #expect(subject.firstLogin == device.creationDate)
        #expect(subject.id == "device-id-2")
        #expect(subject.identifier == "device-identifier-2")
        #expect(subject.isCurrentSession == false)
        #expect(subject.isTrusted == false)
        #expect(subject.lastActivityDate == device.lastActivityDate)
        #expect(subject.pendingRequest == nil)
        #expect(subject.hasPendingRequest == false)
    }

    /// `init(device:timeProvider:)` computes `activityStatus` from the device's last activity
    /// date relative to the time provider.
    @Test
    func init_device_computesActivityStatus() {
        let device = DeviceResponse.fixture(lastActivityDate: timeProvider.presentTime)

        let subject = DeviceListItem(device: device, timeProvider: timeProvider)

        #expect(subject.activityStatus == .today)
    }

    /// `init(device:timeProvider:)` sets `activityStatus` to `.unknown` when the device has no
    /// last activity date.
    @Test
    func init_device_nilLastActivityDate() {
        let device = DeviceResponse.fixture(lastActivityDate: nil)

        let subject = DeviceListItem(device: device, timeProvider: timeProvider)

        #expect(subject.activityStatus == .unknown)
        #expect(subject.lastActivityDate == nil)
    }

    /// `hasPendingRequest` is `true` once a pending request is assigned.
    @Test
    func hasPendingRequest_withPendingRequest() {
        var subject = DeviceListItem(device: .fixture(), timeProvider: timeProvider)
        subject.pendingRequest = .fixture()

        #expect(subject.hasPendingRequest)
    }
}
