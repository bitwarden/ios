@testable import BitwardenShared

class MockApplication: Application {
    var registerForRemoteNotificationsCalled = false

    func registerForRemoteNotifications() {
        registerForRemoteNotificationsCalled = true
    }
}
