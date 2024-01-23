import Foundation

/// A protocol for an API service used to make auth requests.
///
protocol AuthAPIService {
    /// Performs the identity token request and returns the response.
    ///
    /// - Parameter request: The user's authentication details.
    /// - Returns: The identity token response containing an access token.
    ///
    func getIdentityToken(_ request: IdentityTokenRequestModel) async throws -> IdentityTokenResponseModel

    /// Gets the pending login requests.
    ///
    /// - Returns: The pending login requests.
    ///
    func getPendingLoginRequests() async throws -> [LoginRequest]

    /// Query the API to determine if the user's email is able to use single sign on and if the organization
    /// identifier is already known.
    ///
    /// - Parameter email: The user's email address.
    /// - Returns: A `SingleSignOnDetailsResponse`.
    ///
    func getSingleSignOnDetails(email: String) async throws -> SingleSignOnDetailsResponse

    /// Queries the API to pre-validate single-sign on for the requested organization identifier.
    ///
    /// - Parameter organizationIdentifier: The organization identifier.
    ///
    /// - Returns: A `PreValidateSingleSignOnResponse`.
    ///
    func preValidateSingleSignOn(organizationIdentifier: String) async throws -> PreValidateSingleSignOnResponse

    /// Performs the identity token refresh request to get a new access token.
    ///
    /// - Parameter request: The user's refresh token used to get a new access token.
    /// - Returns: The identity token refresh response containing a new access token.
    ///
    func refreshIdentityToken(refreshToken: String) async throws -> IdentityTokenRefreshResponseModel

    /// Sends the request to email the user another verification code.
    ///
    /// - Parameter model: The data needed to send the request.
    ///
    func resendEmailCode(_ model: ResendEmailCodeRequestModel) async throws
}

extension APIService: AuthAPIService {
    func getIdentityToken(_ request: IdentityTokenRequestModel) async throws -> IdentityTokenResponseModel {
        try await identityService.send(IdentityTokenRequest(requestModel: request))
    }

    func getPendingLoginRequests() async throws -> [LoginRequest] {
        // Filter the response to only show the non-expired, non-answered requests.
        try await apiService.send(PendingLoginsRequest())
            .data
            .filter { request in
                let isAnswered = request.requestApproved != nil && request.responseDate != nil

                let expirationDate = Calendar.current.date(
                    byAdding: .minute,
                    value: Constants.loginRequestTimeoutMinutes,
                    to: request.creationDate
                ) ?? Date()
                let isExpired = expirationDate < Date()

                return !isAnswered && !isExpired
            }
    }

    func getSingleSignOnDetails(email: String) async throws -> SingleSignOnDetailsResponse {
        try await apiUnauthenticatedService.send(SingleSignOnDetailsRequest(email: email))
    }

    func preValidateSingleSignOn(organizationIdentifier: String) async throws -> PreValidateSingleSignOnResponse {
        let request = PreValidateSingleSignOnRequest(organizationIdentifier: organizationIdentifier)
        return try await identityService.send(request)
    }

    func refreshIdentityToken(refreshToken: String) async throws -> IdentityTokenRefreshResponseModel {
        try await identityService.send(IdentityTokenRefreshRequest(refreshToken: refreshToken))
    }

    func resendEmailCode(_ model: ResendEmailCodeRequestModel) async throws {
        _ = try await apiUnauthenticatedService.send(ResendEmailCodeRequest(model: model))
    }
}
