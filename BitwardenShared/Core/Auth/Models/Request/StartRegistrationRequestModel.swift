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

    /// The user name.
    let receiveMarketingEmails: Bool
}

// MARK: JSONRequestBody

extension StartRegistrationRequestModel: JSONRequestBody {
    static let encoder = JSONEncoder()
}
