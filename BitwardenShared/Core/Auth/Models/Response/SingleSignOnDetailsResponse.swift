import Foundation
import Networking

// MARK: - SingleSignOnDetailsResponse

/// The response returned from the API when requesting the single sign on details.
///
struct SingleSignOnDetailsResponse: JSONResponse, Equatable {
    static let decoder = JSONDecoder.pascalOrSnakeCaseDecoder

    // MARK: Properties

    /// The organization identifier for the user, if it's known.
    let organizationIdentifier: String?

    /// Whether single sign on is available for the user.
    let ssoAvailable: Bool
}
