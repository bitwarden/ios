import Foundation

// MARK: - EventData

/// Domain model for tracked events.
///
public struct EventData: Codable, Equatable {
    let type: EventType
    let cipherId: String?
    let date: Date
}
