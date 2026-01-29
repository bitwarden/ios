import Foundation

// MARK: - EventData

/// Domain model for tracked events.
///
public struct EventData: Codable, Equatable, Sendable {
    /// The type of event.
    let type: EventType

    /// The ID of the cipher related to the event, if there is one.
    let cipherId: String?

    /// The ID of the organization related to the event, if there is one.
    let organizationId: String?

    /// The time when the event occurred.
    let date: Date
}
