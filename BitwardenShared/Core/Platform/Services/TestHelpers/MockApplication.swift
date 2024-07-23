import UIKit

@testable import BitwardenShared

class MockApplication: Application {
    var beginBackgroundTaskName: String?
    var beginBackgroundTaskHandler: (() -> Void)?
    var beginBackgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    var endBackgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    var registerForRemoteNotificationsCalled = false

    func beginBackgroundTask(withName: String?, expirationHandler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        beginBackgroundTaskName = withName
        beginBackgroundTaskHandler = expirationHandler
        return beginBackgroundTaskIdentifier
    }

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        endBackgroundTaskIdentifier = identifier
    }

    func registerForRemoteNotifications() {
        registerForRemoteNotificationsCalled = true
    }
}
