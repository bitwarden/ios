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

    // MARK: Initialization

    /// Initializes a `StartRegistrationRequestModel`.
    ///
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - name: The user's name.
    ///   - receiveMarketingEmails: If the user wants to receive marketing emails.
    ///
    init(
        email: String,
        name: String,
        receiveMarketingEmails: Bool
    ) {
        self.email = email
        self.name = name
        self.receiveMarketingEmails = receiveMarketingEmails
    }
}

// MARK: JSONRequestBody

extension StartRegistrationRequestModel: JSONRequestBody {
    static let encoder = JSONEncoder()
}
