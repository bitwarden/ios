import UIKit

@testable import BitwardenShared

class MockApplication: Application {
    var applicationState: UIApplication.State = .active
    var beginBackgroundTaskName: String?
    var beginBackgroundTaskHandler: (() -> Void)?
    var beginBackgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    var endBackgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    var registerForRemoteNotificationsCalled = false

    func startBackgroundTask(withName: String?, expirationHandler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        // See note in `UIApplication+Application.swift`
        // TODO: PM-11189
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
