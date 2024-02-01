import Foundation
import Networking

// MARK: - GetSendRequest

struct GetSendRequest: Request {
    typealias Response = SendResponseModel

    let sendId: String

    var path: String { "/sends/\(sendId)" }

    let method: HTTPMethod = .get

    /// Creates a new `GetSendRequest`.
    ///
    /// - Parameter sendId: The id of the send to retrieve.
    ///
    init(sendId: String) {
        self.sendId = sendId
    }
}
