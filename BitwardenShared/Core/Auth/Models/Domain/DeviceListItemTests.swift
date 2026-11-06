import BitwardenKitMocks
import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - DeviceListItemTests

struct DeviceListItemTests {
    // MARK: Properties

    let timeProvider = MockTimeProvider(.mockTime(Date(timeIntervalSince1970: 1_718_452_200)))

    // MARK: Initialization Tests

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
        #expect(subject.pendingAuthRequestId == nil)
        #expect(subject.pendingRequest == nil)
        #expect(subject.hasPendingRequest == false)
    }

    /// `init(device:timeProvider:)` maps `pendingAuthRequestId` from the device's
    /// `devicePendingAuthRequest`, when present.
    @Test
    func init_device_pendingAuthRequestId() {
        let device = DeviceResponse.fixture(
            devicePendingAuthRequest: .fixture(id: "auth-request-id"),
        )

        let subject = DeviceListItem(device: device, timeProvider: timeProvider)

        #expect(subject.pendingAuthRequestId == "auth-request-id")
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

    // MARK: Comparable Tests

    /// `<` orders the current session before any other device.
    @Test
    func lessThan_currentSessionFirst() {
        let currentSession = DeviceListItem.fixture(id: "current", isCurrentSession: true)
        let other = DeviceListItem.fixture(id: "other", isCurrentSession: false)

        #expect(currentSession < other)
        #expect(!(other < currentSession))
    }

    /// `<` orders a device with a pending request before one without, when neither is the
    /// current session.
    @Test
    func lessThan_pendingRequestSecond() {
        var pending = DeviceListItem.fixture(id: "pending")
        pending.pendingRequest = .fixture()
        let notPending = DeviceListItem.fixture(id: "not-pending")

        #expect(pending < notPending)
        #expect(!(notPending < pending))
    }

    /// `<` orders devices by the most recent activity date when neither is the current session
    /// nor has a pending request.
    @Test
    func lessThan_mostRecentActivityFirst() {
        let recent = DeviceListItem.fixture(
            id: "recent",
            lastActivityDate: Date(timeIntervalSince1970: 2_000_000),
        )
        let older = DeviceListItem.fixture(
            id: "older",
            lastActivityDate: Date(timeIntervalSince1970: 1_000_000),
        )

        #expect(recent < older)
        #expect(!(older < recent))
    }

    /// `<` orders a device with a known activity date before one without.
    @Test
    func lessThan_knownActivityBeforeUnknown() {
        let known = DeviceListItem.fixture(id: "known", lastActivityDate: Date())
        let unknown = DeviceListItem.fixture(id: "unknown", lastActivityDate: nil)

        #expect(known < unknown)
        #expect(!(unknown < known))
    }

    /// `<` falls back to the most recent first-login date when neither device has a known
    /// activity date.
    @Test
    func lessThan_fallsBackToFirstLogin() {
        let newer = DeviceListItem.fixture(
            firstLogin: Date(timeIntervalSince1970: 2_000_000),
            id: "newer",
            lastActivityDate: nil,
        )
        let older = DeviceListItem.fixture(
            firstLogin: Date(timeIntervalSince1970: 1_000_000),
            id: "older",
            lastActivityDate: nil,
        )

        #expect(newer < older)
        #expect(!(older < newer))
    }
}
