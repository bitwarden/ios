import Foundation
import Networking

// MARK: - StartRegistrationRequestModel

/// The data to include in the body of a `StartRegistrationRequest`.
///
struct StartRegistrationRequestModel: Equatable {
    // MARK: Properties

    /// The captcha response used in validating a user for this request.
    let captchaResponse: String?

    /// The user's email address.
    let email: String

    /// The user name.
    let name: String

    // MARK: Initialization

    /// Initializes a `StartRegistrationRequestModel`.
    ///
    /// - Parameters:
    ///   - captchaResponse: The captcha response used in validating a user for this request.
    ///   - email: The user's email address.
    ///   - name: The user's name.
    ///
    init(
        captchaResponse: String? = nil,
        email: String,
        name: String
    ) {
        self.captchaResponse = captchaResponse
        self.email = email
        self.name = name
    }
}

// MARK: JSONRequestBody

extension StartRegistrationRequestModel: JSONRequestBody {
    static let encoder = JSONEncoder()
}
