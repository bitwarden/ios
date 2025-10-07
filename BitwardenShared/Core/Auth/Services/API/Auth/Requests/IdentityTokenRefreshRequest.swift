import BitwardenKit
import Networking

// MARK: - IdentityTokenRefreshRequestError

/// Errors that can occur when sending an `IdentityTokenRefreshRequest`.
enum IdentityTokenRefreshRequestError: NonLoggableError, Equatable {
    /// Not allowed because of invalid grant.
    case invalidGrant
}

// MARK: - IdentityTokenRefreshRequest

/// Data model for performing a identity token refresh request.
///
struct IdentityTokenRefreshRequest: Request {
    typealias Response = IdentityTokenRefreshResponseModel

    // MARK: Properties

    /// The body of the request.
    var body: IdentityTokenRefreshRequestModel? {
        requestModel
    }

    /// The HTTP method for this request.
    let method = HTTPMethod.post

    /// The URL path for this request.
    let path = "/connect/token"

    /// The request details to include in the body of the request.
    let requestModel: IdentityTokenRefreshRequestModel

    // MARK: Initialization

    /// Initialize an `IdentityTokenRefreshRequest`.
    ///
    /// - Parameter refreshToken: The refresh token used to get a new access token.
    ///
    init(refreshToken: String) {
        requestModel = IdentityTokenRefreshRequestModel(refreshToken: refreshToken)
    }

    // MARK: Methods

    func validate(_ response: HTTPResponse) throws {
        if response.statusCode == 400 {
            guard let errorModel = try? IdentityTokenErrorModel.decoder.decode(
                IdentityTokenErrorModel.self,
                from: response.body,
            ) else { return }

            if let error = errorModel.error,
               error == IdentityTokenError.invalidGrant {
                throw IdentityTokenRefreshRequestError.invalidGrant
            }
        }
    }
}
