import Foundation
import Networking

// MARK: - ResendEmailCodeRequest

/// A request for re-sending the two-factor verification code email.
///
struct ResendEmailCodeRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The body of the request.
    var body: ResendEmailCodeRequestModel? { model }

    /// The HTTP method for this request.
    var method: HTTPMethod { .post }

    /// The URL path for this request.
    var path: String { "/two-factor/send-email-login" }

    /// The data to attach to the body of the request.
    let model: ResendEmailCodeRequestModel
}
