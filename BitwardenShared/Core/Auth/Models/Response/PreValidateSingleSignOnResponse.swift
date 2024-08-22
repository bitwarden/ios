import Foundation
import Networking

// MARK: - PreValidateSingleSignOnResponse

/// The response returned from the API upon pre-validating the single-sign on.
///
struct PreValidateSingleSignOnResponse: JSONResponse, Equatable {
    static let decoder = JSONDecoder()

    // MARK: Properties

    /// The token returned in this response.
    var token: String
}
