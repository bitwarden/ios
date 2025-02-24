import UIKit

@testable import AuthenticatorShared

class MockApplication: Application {
    var canOpenUrlResponse = false
    var registerForRemoteNotificationsCalled = false

    func canOpenURL(_ url: URL) -> Bool {
        canOpenUrlResponse
    }

    func registerForRemoteNotifications() {
        registerForRemoteNotificationsCalled = true
    }
}
