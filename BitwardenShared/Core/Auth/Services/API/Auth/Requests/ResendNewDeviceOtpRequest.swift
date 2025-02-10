import Foundation
import Networking

// MARK: - ResendNewDeviceOtpRequest

/// A request for re-sending the device verification code to email.
///
struct ResendNewDeviceOtpRequest: Request {
    typealias Response = EmptyResponse

    // MARK: Properties

    /// The body of the request.
    var body: ResendNewDeviceOtpRequestModel? { model }

    /// The HTTP method for this request.
    var method: HTTPMethod { .post }

    /// The URL path for this request.
    var path: String { "/accounts/resend-new-device-otp" }

    /// The data to attach to the body of the request.
    let model: ResendNewDeviceOtpRequestModel
}
