import Foundation
import Networking

// MARK: - StartRegistrationRequestModel

/// The data to include in the body of a `StartRegistrationRequest`.
///
struct StartRegistrationRequestModel: Equatable {
    // MARK: Properties

    /// The user's email address.
    let email: String

    /// The user name.
    let name: String

    /// If the user wants to receive marketing emails.
    let receiveMarketingEmails: Bool
}

// MARK: JSONRequestBody

extension StartRegistrationRequestModel: JSONRequestBody {
    static let encoder = JSONEncoder()
}
