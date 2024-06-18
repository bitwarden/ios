import Foundation

// MARK: - EventService

/// A protocol for a service that manages organization events. This includes saving events to disk
/// and uploading those events.
///
protocol EventService {
    /// Save an event to disk for future upload.
    ///
    /// - Parameters:
    ///   - eventType: The event to track.
    ///   - cipherId: The ID of the relevant cipher for some events.
    ///   - uploadImmediately: If `true` then immediately attempts an upload after saving.
    func collect(eventType: EventType, cipherId: String?, uploadImmediately: Bool) async
}

extension EventService {
    func collect(
        eventType: EventType,
        cipherId: String? = nil,
        uploadImmediately: Bool = false
    ) async {
        await collect(eventType: eventType, cipherId: cipherId, uploadImmediately: uploadImmediately)
    }
}

// MARK: - DefaultEventService

/// The default implementation of an `EventService`.
///
class DefaultEventService: EventService {
    // MARK: Properties

    // MARK: Initialization

    // MARK: Methods

    func collect(eventType: EventType, cipherId: String?, uploadImmediately: Bool) async {}
}
