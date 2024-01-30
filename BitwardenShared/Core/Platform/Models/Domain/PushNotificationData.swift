import Foundation

// MARK: - PushNotificationData

struct PushNotificationData: Codable {
    // MARK: Properties

    /// The context Id, which should match the app id.
    let contextId: String?

    /// The payload of the push notification.
    let payload: String?

    /// The type of notification.
    let type: NotificationType?

    // MARK: Methods

    /// Convert the payload string into data.
    func data<T: Codable>() -> T? {
        if let data = payload?.data(using: .utf8),
           let object = try? JSONDecoder.pascalOrSnakeCaseDecoder.decode(T.self, from: data) {
            return object
        }
        return nil
    }
}

// MARK: - SyncCipherNotification

/// Additional information that can be contained in the push notification payload for certain types of notifications.
struct SyncCipherNotification: Codable, Equatable {
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
struct SyncFolderNotification: Codable, Equatable {
    /// The id of the folder.
    let id: String

    /// The revision date of the folder.
    let revisionDate: Date?

    /// The user id that owns the folder.
    let userId: String
}

// MARK: - UserNotification

/// Additional information that can be contained in the push notification payload for certain types of notifications.
struct UserNotification: Codable, Equatable {
    /// The date of the notification.
    let date: Date?

    /// The user id that needs to be updated.
    let userId: String
}

// MARK: - SyncSendNotification

/// Additional information that can be contained in the push notification payload for certain types of notifications.
struct SyncSendNotification: Codable, Equatable {
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

/// The data structure of the information attached to the in-app foreground notification.
struct LoginRequestPushNotification: Codable, Equatable {
    /// How long until the request times out.
    let timeoutInMinutes: Int

    /// The email of the account sending the login request.
    let userEmail: String
}
