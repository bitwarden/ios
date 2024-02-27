import Foundation
import UserNotifications

@testable import BitwardenShared

class MockNotificationService: NotificationService {
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    var delegate: NotificationServiceDelegate?
    var messageReceivedMessage: [AnyHashable: Any]?
    var registrationTokenData: Data?
    var requestAuthorizationResult: Result<Bool, Error> = .success(true)
    var requestedOptions: UNAuthorizationOptions?

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

    func notificationAuthorization() async -> UNAuthorizationStatus {
        authorizationStatus
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestedOptions = options
        return try requestAuthorizationResult.get()
    }

    func setDelegate(_ delegate: NotificationServiceDelegate?) {
        self.delegate = delegate
    }
}
