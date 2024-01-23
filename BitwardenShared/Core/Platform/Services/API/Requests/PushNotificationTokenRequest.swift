import Foundation
import Networking

// MARK: - PushNotificationTokenRequestBody

/// Data model for the body of a push notification token request.
///
struct PushNotificationTokenRequestBody: JSONRequestBody {
    /// The decoded push notification token received when registering for push notifications.
    let pushToken: String
}

// MARK: - PushNotificationTokenRequest

/// Data model for performing a push notification token request.
///
struct PushNotificationTokenRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The app id.
    let appId: String

    /// The body of this request.
    var body: PushNotificationTokenRequestBody? { requestBody }

    /// The HTTP method for this request.
    var method: HTTPMethod { .put }

    /// The URL path for this request.
    var path: String { "/devices/identifier/\(appId)/token" }

    /// The body of the request.
    let requestBody: PushNotificationTokenRequestBody
}
