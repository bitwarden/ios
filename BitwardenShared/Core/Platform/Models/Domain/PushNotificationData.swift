import BitwardenKit
import Foundation

// MARK: - PushNotificationData

struct PushNotificationData: Codable {
    // MARK: Properties

    /// The context Id, which should match the app ID.
    let contextId: String?

    /// The payload of the push notification.
    let payload: String?

    /// The type of notification.
    let type: NotificationType?

    // MARK: Methods

    /// Convert the payload string into data.
    ///
    /// - Throws: `PushNotificationDataError.payloadDecodingFailed` if the payload is absent,
    ///   empty, or cannot be decoded as `T`.
    ///
    func data<T: Codable>() throws -> T {
        do {
            guard let payloadString = payload, !payloadString.isEmpty else {
                throw BitwardenError.dataError("Push notification payload is nil or empty")
            }
            return try JSONDecoder.pascalOrSnakeCaseDecoder.decode(T.self, from: Data(payloadString.utf8))
        } catch {
            throw PushNotificationDataError.payloadDecodingFailed(type: type, underlyingError: error)
        }
    }
}

// MARK: - PushNotificationData + userInfo

extension PushNotificationData {
    /// Decodes a `PushNotificationData` from a notification's `userInfo` dictionary.
    ///
    /// - Parameter userInfo: The notification's `userInfo` dictionary.
    /// - Returns: The decoded `PushNotificationData`.
    /// - Throws: `PushNotificationDataError.missingDataDictionary` if the `"data"` key is absent,
    ///   or an error if JSON serialization or decoding fails.
    ///
    init(userInfo: [AnyHashable: Any]) throws {
        guard let messageContent = userInfo["data"] as? [AnyHashable: Any] else {
            throw PushNotificationDataError.missingDataDictionary
        }
        let jsonData = try JSONSerialization.data(withJSONObject: messageContent)
        self = try JSONDecoder().decode(PushNotificationData.self, from: jsonData)
    }
}

// MARK: - PushNotificationDataError

/// An error thrown when a push notification payload cannot be decoded.
///
enum PushNotificationDataError: Error, CustomNSError {
    /// Thrown when the notification's `userInfo` dictionary does not contain a `"data"` key.
    case missingDataDictionary

    /// Thrown when the push notification payload cannot be decoded into the expected type.
    case payloadDecodingFailed(type: NotificationType?, underlyingError: Error)

    var errorCode: Int {
        // NOTE: New cases should be appended (vs alphabetized) to this switch statement with an
        // incremented integer. This ensures the code for existing errors doesn't change.
        switch self {
        case .payloadDecodingFailed: 1
        case .missingDataDictionary: 2
        }
    }

    var errorUserInfo: [String: Any] {
        var userInfo: [String: Any] = [
            "Error Type": String(reflecting: self),
        ]

        switch self {
        case .missingDataDictionary:
            break
        case let .payloadDecodingFailed(type, underlyingError):
            userInfo[NSUnderlyingErrorKey] = underlyingError
            if let type {
                userInfo["Notification Type"] = String(reflecting: type)
            }
        }

        return userInfo
    }
}

// MARK: - NotificationWithUser

/// A push notification payload that includes a user ID.
///
protocol NotificationWithUser {
    /// The user ID associated with this notification.
    var userId: String { get }
}

// MARK: - SyncCipherNotification

/// Additional information that can be contained in the push notification payload for certain types of notifications.
struct SyncCipherNotification: Codable, Equatable, NotificationWithUser {
    /// The collection ids of the cipher.
    let collectionIds: [String]?

    /// The id of the cipher.
    let id: String

    /// The organization ids of the cipher.
    let organizationId: String?

    /// The revision date of the cipher.
    let revisionDate: Date?

    /// The user id that owns the cipher.
    let userId: String
}

// MARK: - SyncFolderNotification

/// Additional information that can be contained in the push notification payload for certain types of notifications.
struct SyncFolderNotification: Codable, Equatable, NotificationWithUser {
    /// The id of the folder.
    let id: String

    /// The revision date of the folder.
    let revisionDate: Date?

    /// The user id that owns the folder.
    let userId: String
}

// MARK: - UserNotification

/// Additional information that can be contained in the logout push notification payload.
struct LogoutNotification: Codable, Equatable {
    // MARK: Types

    /// The reason why a user is being logged out.
    enum PushNotificationLogOutReason: Int, Codable, DefaultValueProvider {
        /// The logout was triggered by a KDF setting change.
        case kdfChange = 0

        /// An unknown or unimplemented reason.
        case unknown = -1

        static var defaultValue: Self {
            .unknown
        }
    }

    // MARK: Properties

    /// The date of the notification.
    let date: Date?

    /// The reason why the user is being logged out.
    @DefaultValue var reason: PushNotificationLogOutReason

    /// The user id that needs to be updated.
    let userId: String
}

// MARK: - SyncSendNotification

/// Additional information that can be contained in the push notification payload for certain types of notifications.
struct SyncSendNotification: Codable, Equatable, NotificationWithUser {
    /// The id of the send.
    let id: String

    /// The revision date of the send.
    let revisionDate: Date?

    /// The user id that owns the send.
    let userId: String
}

// MARK: - LoginRequestNotification

/// Additional information that can be contained in the push notification payload for certain types of notifications.
struct LoginRequestNotification: Codable, Equatable {
    /// The id of the login request.
    let id: String

    /// The user id associated with the login request.
    let userId: String
}

// MARK: - LoginRequestPushNotification

// TODO: PM-33817 - Remove `LoginRequestPushNotification` once the server fully switches to alert-style
// push notifications and local notification banners are no longer created for auth requests.

/// The data structure of the information attached to the in-app foreground notification.
struct LoginRequestPushNotification: Codable, Equatable {
    /// The id of the login request.
    let id: String?

    /// How long until the request times out.
    let timeoutInMinutes: Int

    /// The user id that sent the login request.
    let userId: String
}
