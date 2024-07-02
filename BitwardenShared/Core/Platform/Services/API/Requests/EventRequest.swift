import Networking

// MARK: - EventRequest

/// A request for uploading organization events.
struct EventRequest: Request {
    typealias Response = EmptyResponse

    let body: EventData

    let method: HTTPMethod = .post

    let path = "/collect"
}
