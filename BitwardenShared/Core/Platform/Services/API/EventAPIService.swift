import Foundation
import Networking

/// A protocol for an API service used to make event requests.
///
protocol EventAPIService {
    /// Performs an API request to send an event to the backend.
    ///
    /// - Parameters:
    ///   - body: The request model to send.
    ///
    func postEvents(_ events: [EventData]) async throws
}

extension APIService: EventAPIService {
    func postEvents(_ events: [EventData]) async throws {
        let models = events.map { event in
            EventRequestModel(
                type: event.type,
                cipherId: event.cipherId,
                date: event.date
            )
        }
        _ = try await eventsService.send(
            EventRequest(requestBody: EventRequestBody(events: models))
        )
    }
}
