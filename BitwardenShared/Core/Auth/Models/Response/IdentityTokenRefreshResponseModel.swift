import Foundation
import Networking

/// API response model for the identity token refresh request.
///
struct IdentityTokenRefreshResponseModel: JSONResponse, Equatable {
    static let decoder = JSONDecoder.snakeCaseDecoder

    // MARK: Properties

    /// The user's access token.
    let accessToken: String

    /// The number of seconds before the access token expires.
    let expiresIn: Int

    /// The type of token.
    let tokenType: String

    /// The user's refresh token.
    let refreshToken: String
}
