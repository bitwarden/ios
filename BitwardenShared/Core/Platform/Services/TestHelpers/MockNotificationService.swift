import Foundation

@testable import BitwardenShared

class MockNotificationService: NotificationService {
    var messageReceivedMessage: [AnyHashable: Any]?
    var registrationTokenData: Data?

    func didRegister(withToken tokenData: Data) async {
        registrationTokenData = tokenData
    }

    func messageReceived(
        _ message: [AnyHashable: Any],
        notificationDismissed _: Bool?,
        notificationTapped _: Bool?
    ) async {
        messageReceivedMessage = message
    }
}
