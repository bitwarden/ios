import Foundation

// MARK: - AgentAccessPushNotification

/// The payload of an Agent Access push notification, sent when a request is waiting at the relay.
///
struct AgentAccessPushNotification: Codable, Equatable, NotificationWithUser {
    /// The recipient identity fingerprint (64 hex), the one the relay saw.
    let fingerprint: String

    /// The ID of the user the notification is for.
    let userId: String
}
