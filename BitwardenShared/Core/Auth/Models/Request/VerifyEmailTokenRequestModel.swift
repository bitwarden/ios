import Foundation
import Networking

// MARK: - VerifyEmailTokenRequestRequestModel

/// The data to include in the body of a `VerifyEmailTokenRequestRequest`.
///
struct VerifyEmailTokenRequestModel: Equatable {
    // MARK: Properties

    /// The email being used to create the account.
    let email: String

    /// The token used to verify the email.
    let emailVerificationToken: String
}

// MARK: JSONRequestBody

extension VerifyEmailTokenRequestModel: JSONRequestBody {
    static let encoder = JSONEncoder()
}
