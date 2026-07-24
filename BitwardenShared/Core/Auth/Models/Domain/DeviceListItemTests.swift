import Foundation
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - DeviceListItemTests

struct DeviceListItemTests {
    // MARK: Tests

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
