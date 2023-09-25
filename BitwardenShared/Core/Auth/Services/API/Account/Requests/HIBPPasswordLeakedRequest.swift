import Foundation
import Networking

// MARK: - HIBPPasswordLeakedRequest

/// The API request sent when checking if a password has appeared in a data breach.
///
class HIBPPasswordLeakedRequest: Request {
    typealias Response = HIBPResponseModel

    /// The prefix of the user's entered password.
    let passwordHashPrefix: String

    /// The URL path for this request.
    var path: String {
        "/range/\(passwordHashPrefix)"
    }

    // MARK: Initialization

    /// Initializes an  `HIBPPasswordLeakedRequest` instance.
    ///
    /// - Parameter passwordHashPrefix: The prefix of the user's entered password
    /// that is being checked against data breaches.
    ///
    init(passwordHashPrefix: String) {
        self.passwordHashPrefix = passwordHashPrefix
    }
}
