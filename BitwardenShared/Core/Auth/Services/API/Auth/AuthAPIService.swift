/// A protocol for an API service used to make auth requests.
///
protocol AuthAPIService {
    /// Approves or denies a pending login request.
    ///
    /// - Parameters:
    ///   - id: The id of the login request.
    ///   - requestModel: The body of the API request.
    ///
    /// - Returns: The updated `LoginRequest`.
    ///
    func answerLoginRequest(_ id: String, requestModel: AnswerLoginRequestRequestModel) async throws -> LoginRequest

    /// Check the status of the pending login request for the unauthenticated user.
    ///
    /// - Parameters:
    ///   - id: The id of the login request.
    ///   - accessCode: The access code generated when creating the request.
    ///
    /// - Returns: The pending login request.
    ///
    func checkPendingLoginRequest(withId id: String, accessCode: String) async throws -> LoginRequest

    /// Performs the identity token request and returns the response.
    ///
    /// - Parameter request: The user's authentication details.
    /// - Returns: The identity token response containing an access token.
    ///
    func getIdentityToken(_ request: IdentityTokenRequestModel) async throws -> IdentityTokenResponseModel

    /// Gets a pending login requests.
    ///
    /// - Parameter id: The id of the request to fetch.
    /// - Returns: The pending login request.
    ///
    func getPendingLoginRequest(withId id: String) async throws -> LoginRequest

    /// Gets the pending login requests.
    ///
    /// - Returns: The pending login requests.
    ///
    func getPendingLoginRequests() async throws -> [LoginRequest]

    /// Initiates the login with device process.
    ///
    /// - Parameter requestModel The access code used in the request
    /// - Returns: The new pending login requests.
    ///
    func initiateLoginWithDevice(_ requestModel: LoginWithDeviceRequestModel
    ) async throws -> LoginRequest

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

    /// Sends the request a new verification otp to the user's email.
    ///
    /// - Parameter model: The data needed to send the request.
    ///
    func resendNewDeviceOtp(_ model: ResendNewDeviceOtpRequestModel) async throws

    /// Sends the trusted device keys to the server.
    ///
    /// - Parameters:
    ///   - deviceIdentifier: The user's device ID.
    ///   - model: The data needed to send the request.
    ///
    func updateTrustedDeviceKeys(deviceIdentifier: String, model: TrustedDeviceKeysRequestModel) async throws
}

extension APIService: AuthAPIService {
    func answerLoginRequest(_ id: String, requestModel: AnswerLoginRequestRequestModel) async throws -> LoginRequest {
        try await apiService.send(AnswerLoginRequestRequest(id: id, requestModel: requestModel))
    }

    func checkPendingLoginRequest(withId id: String, accessCode: String) async throws -> LoginRequest {
        try await apiUnauthenticatedService.send(CheckLoginRequestRequest(accessCode: accessCode, id: id))
    }

    func getIdentityToken(_ request: IdentityTokenRequestModel) async throws -> IdentityTokenResponseModel {
        try await identityService.send(IdentityTokenRequest(requestModel: request))
    }

    func getPendingLoginRequest(withId id: String) async throws -> LoginRequest {
        try await apiService.send(PendingLoginRequest(id: id))
    }

    func getPendingLoginRequests() async throws -> [LoginRequest] {
        // Filter the response to only show the non-expired, non-answered requests.
        try await apiService.send(PendingLoginsRequest()).data.filter { !$0.isAnswered && !$0.isExpired }
    }

    func initiateLoginWithDevice(_ requestModel: LoginWithDeviceRequestModel) async throws -> LoginRequest {
        let request = LoginWithDeviceRequest(body: requestModel)
        if request.requestType == AuthRequestType.adminApproval {
            return try await apiService.send(request)
        } else {
            return try await apiUnauthenticatedService.send(request)
        }
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

    func resendNewDeviceOtp(_ model: ResendNewDeviceOtpRequestModel) async throws {
        _ = try await apiUnauthenticatedService.send(ResendNewDeviceOtpRequest(model: model))
    }

    func updateTrustedDeviceKeys(deviceIdentifier: String, model: TrustedDeviceKeysRequestModel) async throws {
        _ = try await apiService.send(TrustedDeviceKeysRequest(deviceIdentifier: deviceIdentifier, requestModel: model))
    }
}
