/// A protocol for an API service used to make auth requests.
///
protocol AuthAPIService {
    /// Performs the identity token request and returns the response.
    ///
    /// - Parameter request: The user's authentication details.
    /// - Returns: The identity token response containing an access token.
    ///
    func getIdentityToken(_ request: IdentityTokenRequestModel) async throws -> IdentityTokenResponseModel

    /// Query the API to determine if the user's email is able to use single sign on and if the organization
    /// identifier is already known.
    ///
    /// - Parameter email: The user's email address.
    /// - Returns: A `SingleSignOnDetailsResponse`.
    ///
    func getSingleSignOnDetails(email: String) async throws -> SingleSignOnDetailsResponse

    /// Initiates the login with device proccess.
    ///
    /// - Parameters:
    ///   - accessCode: The access code used in the request.
    ///   - deviceIdentifier: The user's device ID.
    ///   - email: The user's email.
    ///   - fingerprint: The fingerprint used in the request.
    ///   - publicKey: The key used in the request.
    ///
    func initiateLoginWithDevice(
        accessCode: String,
        deviceIdentifier: String,
        email: String,
        fingerPrint: String,
        publicKey: String
    ) async throws

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
}

extension APIService: AuthAPIService {
    func getIdentityToken(_ request: IdentityTokenRequestModel) async throws -> IdentityTokenResponseModel {
        try await identityService.send(IdentityTokenRequest(requestModel: request))
    }

    func getSingleSignOnDetails(email: String) async throws -> SingleSignOnDetailsResponse {
        try await apiUnauthenticatedService.send(SingleSignOnDetailsRequest(email: email))
    }

    func initiateLoginWithDevice(
        accessCode: String,
        deviceIdentifier: String,
        email: String,
        fingerPrint: String,
        publicKey: String
    ) async throws {
        let req = try await apiUnauthenticatedService.send(
            PasswordlessLoginRequest(
                body: PasswordlessLoginRequestModel(
                    email: email,
                    publicKey: publicKey,
                    deviceIdentifier: deviceIdentifier,
                    accessCode: accessCode,
                    type: 0,
                    fingerprintPhrase: fingerPrint
                )
            )
        )
        print("req", req)
    }

    func preValidateSingleSignOn(organizationIdentifier: String) async throws -> PreValidateSingleSignOnResponse {
        let request = PreValidateSingleSignOnRequest(organizationIdentifier: organizationIdentifier)
        return try await identityService.send(request)
    }

    func refreshIdentityToken(refreshToken: String) async throws -> IdentityTokenRefreshResponseModel {
        try await identityService.send(IdentityTokenRefreshRequest(refreshToken: refreshToken))
    }
}
