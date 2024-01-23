import Networking

/// A protocol for an API service used to make notification requests.
///
protocol NotificationAPIService {
    /// Performs an API request to save the push notification token to the backend.
    ///
    /// - Parameters:
    ///   - appId: The app id.
    ///   - token: The push notification received from successfully registering for push notifications.
    ///
    func savePushNotificationToken(for appId: String, token: String) async throws
}

extension APIService: NotificationAPIService {
    func savePushNotificationToken(for appId: String, token: String) async throws {
        _ = try await apiService.send(PushNotificationTokenRequest(appId: appId, requestBody: .init(pushToken: token)))
    }
}
