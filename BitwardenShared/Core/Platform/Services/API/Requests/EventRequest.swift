import Foundation
import Networking

// MARK: - EventRequestModel

/// Data model for the body of an event upload.
///
struct EventRequestModel: JSONRequestBody {
    /// The type of event.
    let type: EventType

    /// The ID of the cipher related to the event, if there is one.
    let cipherId: String?

    /// The time when the event occurred.
    let date: Date
}

// MARK: - EventRequest

/// A request for uploading organization events.
struct EventRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The body of the request.
    var body: EventRequestModel? { requestBody }

    /// The HTTP method of the request.
    let method: HTTPMethod = .post

    /// The URL path of this request.
    let path = "/collect"

    /// The actual body of the request.
    let requestBody: EventRequestModel
}
