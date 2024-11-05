import Foundation
import Networking

// MARK: - SingleSignOnDomainsVerifiedResponse

/// The response returned from the API when requesting the single sign on verified domains.
///
struct SingleSignOnDomainsVerifiedResponse: JSONResponse, Equatable {
    // MARK: Types

    /// Key names used for encoding and decoding.
    enum CodingKeys: String, CodingKey {
        case verifiedDomains = "data"
    }

    // MARK: Properties

    /// The verified domains for the organization single sign on.
    let verifiedDomains: [SingleSignOnDomainVerifiedDetailResponse]?
}

/// The response returned from the API when requesting the single sign on verified domain for a specific domain.
///
struct SingleSignOnDomainVerifiedDetailResponse: JSONResponse, Equatable {
    static let decoder = JSONDecoder.pascalOrSnakeCaseDecoder

    // MARK: Properties

    /// The domain name.
    let domainName: String?

    /// The organization identifier for the user.
    let organizationIdentifier: String?

    /// The organization name.
    let organizationName: String?
}
