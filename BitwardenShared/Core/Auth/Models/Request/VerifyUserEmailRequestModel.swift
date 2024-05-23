import Foundation
import Networking

// MARK: - VerifyUserEmailRequestModel

/// The data to include in the body of a `VerifyUserEmailRequest`.
///
struct VerifyUserEmailRequestModel: Equatable {
    // MARK: Properties

    /// The user's email address.
    let email: String

    /// The email verification token.
    var emailVerificationToken: String?

    // MARK: Initialization

    /// Initializes a `VerifyUserEmailRequestModel`.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - emailVerificationToken: The email verification token.
    ///
    init(
        email: String,
        emailVerificationToken: String
    ) {
        self.email = email
        self.emailVerificationToken = emailVerificationToken
    }
}

// MARK: JSONRequestBody

extension VerifyUserEmailRequestModel: JSONRequestBody {
    static let encoder = JSONEncoder()
}
