import Foundation
import Networking

/// API request model for refreshing an identity token.
///
struct IdentityTokenRefreshRequestModel {
    // MARK: Properties

    /// The refresh token used to get a new access token.
    let refreshToken: String
}

// MARK: - FormURLEncodedRequestBody

extension IdentityTokenRefreshRequestModel: FormURLEncodedRequestBody {
    var values: [URLQueryItem] {
        [
            URLQueryItem(name: "client_id", value: Constants.clientType),
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
        ]
    }
}
