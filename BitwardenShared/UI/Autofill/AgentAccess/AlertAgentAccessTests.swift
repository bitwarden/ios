import BitwardenKit
import BitwardenResources
import XCTest

@testable import BitwardenShared

class AlertAgentAccessTests: BitwardenTestCase {
    /// `agentAccessNotificationsOff(openSettings:)` explains the loss and offers to open settings.
    func test_agentAccessNotificationsOff() async throws {
        var opened = false
        let subject = Alert.agentAccessNotificationsOff { opened = true }

        XCTAssertEqual(subject.title, Localizations.notificationsAreOff)
        XCTAssertEqual(subject.message, Localizations.agentAccessNotificationsOffWarning)
        XCTAssertEqual(subject.alertActions.map(\.title), [Localizations.openSettings, Localizations.cancel])

        let action = try XCTUnwrap(subject.alertActions.first)
        await action.handler?(action, [])
        XCTAssertTrue(opened)
    }
}
