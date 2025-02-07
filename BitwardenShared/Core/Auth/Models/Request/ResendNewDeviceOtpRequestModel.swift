import Foundation
import Networking

// MARK: - ResendNewDeviceOtpRequestModel

/// API request model for re-sending the device verification code to email.
///
struct ResendNewDeviceOtpRequestModel: JSONRequestBody {
    // MARK: Static Properties

    static let encoder = JSONEncoder()

    // MARK: Properties

    /// The email to send the verification code to.
    let email: String

    /// The master password hash, if available.
    let masterPasswordHash: String?
}
