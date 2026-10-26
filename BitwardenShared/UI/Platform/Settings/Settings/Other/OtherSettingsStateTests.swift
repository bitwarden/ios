import UserNotifications
import XCTest

@testable import BitwardenShared

class OtherSettingsStateTests: BitwardenTestCase {
    // MARK: Tests

    /// `showAgentAccessNotificationsWarning` is only true when Agent Access is on and
    /// notifications are off.
    func test_showAgentAccessNotificationsWarning() {
        var subject = OtherSettingsState()

        subject.isAgentAccessEnabled = true
        subject.notificationAuthorization = .denied
        XCTAssertTrue(subject.showAgentAccessNotificationsWarning)

        subject.notificationAuthorization = .notDetermined
        XCTAssertTrue(subject.showAgentAccessNotificationsWarning)

        subject.notificationAuthorization = .authorized
        XCTAssertFalse(subject.showAgentAccessNotificationsWarning)

        subject.notificationAuthorization = .provisional
        XCTAssertFalse(subject.showAgentAccessNotificationsWarning)

        subject.isAgentAccessEnabled = false
        subject.notificationAuthorization = .denied
        XCTAssertFalse(subject.showAgentAccessNotificationsWarning)
    }
}
