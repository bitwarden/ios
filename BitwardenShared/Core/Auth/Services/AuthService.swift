import BitwardenSdk
import CryptoKit
import Foundation

// MARK: - AuthServiceError

/// A set of errors that could occur during authentication.
///
enum AuthError: Error {
    /// The request that should've been cached is somehow missing.
    case missingData

    /// The device key from trusting the device is missing.
    case missingDeviceKey

    /// The device key from trusting the device is missing.
    case missingUserDecryptionOptions

    /// The data that should have been cached for the login with device method was missing.
    case missingLoginWithDeviceData

    /// The key used for login with device was missing.
    case missingLoginWithDeviceKey

    /// The request that should have been cached for the two-factor authentication method was missing.
    case missingTwoFactorRequest

    /// The user doesn't have a master password set; one needs to be set before continuing.
    case requireSetPassword

    /// The user needs to update the temporary password; one needs to be set before continuing.
    case requireUpdatePassword

    /// The user needs to choose a decryption option before continuing to vault.
    case requireDecryptionOptions

    /// There was a problem extracting the code from the Duo WebAuth response.
    case unableToDecodeDuoResponse

    /// There was a problem extracting the code from the single sign on WebAuth response.
    case unableToDecodeSSOResponse

    /// There was a problem generating the single sign on url.
    case unableToGenerateSSOUrl

    /// There was a problem generating the identity token request.
    case unableToGenerateRequest

    /// There was a problem generating the request to resend the email.
    case unableToResendEmail
}

// MARK: - AuthService

/// A protocol for a service used that handles the auth logic.
///
protocol AuthService {
    /// The callback url scheme for this application.
    var callbackUrlScheme: String { get }

    /// Answer (approve or deny) a pending login request.
    ///
    /// - Parameters:
    ///   - request: The request to answer.
    ///   - approve: Whether to approve the request.
    ///
    func answerLoginRequest(_ request: LoginRequest, approve: Bool) async throws

    /// Check the status of the pending login request for the unauthenticated user.
    ///
    func checkPendingLoginRequest(withId id: String) async throws -> LoginRequest

    /// Deny all the pending login requests.
    ///
    /// - Parameter requests: The list of login requests to deny.
    ///
    func denyAllLoginRequests(_ requests: [LoginRequest]) async throws

    /// Generates a url for use when proceeding through the single sign on flow flow.
    ///
    /// - Parameter organizationIdentifier: The organization identifier.
    ///
    /// - Returns: The url to use when opening the single sign on flow and the state that the
    ///   auth result will have to match.
    ///
    func generateSingleSignOnUrl(from organizationIdentifier: String) async throws -> (url: URL, state: String)

    /// Gets the pending admin login request for a user ID.
    ///
    /// - Parameter userId: The user ID associated with the pending admin login request.
    /// - Returns: The pending admin login request.
    ///
    func getPendingAdminLoginRequest(userId: String?) async throws -> PendingAdminLoginRequest?

    /// Get a specific login request, or all the pending login requests if the id is `nil`.
    ///
    func getPendingLoginRequest(withId id: String?) async throws -> [LoginRequest]

    /// Creates a hash value for the user's master password.
    ///
    /// - Parameters:
    ///   - password: The password text to hash.
    ///   - purpose: The purpose of the hash.
    ///
    /// - Returns: A hash value of the password.
    ///
    func hashPassword(password: String, purpose: HashPurpose) async throws -> String

    /// Initiates the login with device process.
    ///
    /// - Parameters:
    ///  - email: The user's email.
    ///  - type: The auth request type.
    ///
    /// - Returns: The auth request response containing the fingerprint for the new login request
    ///     and the id of the login request, used to check for a response.
    ///
    func initiateLoginWithDevice(
        email: String,
        type: AuthRequestType
    ) async throws -> (authRequestResponse: AuthRequestResponse, requestId: String)

    /// Login with the response received from a login with device request.
    ///
    /// - Parameters:
    ///   - loginRequest: The approved login request.
    ///   - email: The user's email.
    ///   - captchaToken: An optional captcha token value to add to the token request.
    ///   - isAuthenticated: If the user came from sso and is already authenticated
    /// - Returns: A tuple containing the private key from the auth request and the encrypted user key.
    ///
    func loginWithDevice(
        _ loginRequest: LoginRequest,
        email: String,
        isAuthenticated: Bool,
        captchaToken: String?
    ) async throws -> (String, String)

    /// Login with the master password.
    ///
    /// - Parameters:
    ///   - password: The master password.
    ///   - username: The username.
    ///   - captchaToken: An optional captcha token value to add to the token request.
    ///
    func loginWithMasterPassword(_ password: String, username: String, captchaToken: String?) async throws

    /// Login with the single sign on code.
    ///
    /// - Parameters:
    ///   - code: The code received from the single sign on WebAuth flow.
    ///   - email: The user's email address.
    ///
    /// - Returns: The account to unlock the vault for, or nil if the vault does not need to be unlocked.
    ///
    func loginWithSingleSignOn(code: String, email: String) async throws -> Account?

    /// Continue the previous login attempt with the addition of the two-factor information.
    ///
    /// - Parameters:
    ///   - email: The user's email, used to cache the token if remember is true.
    ///   - code: The two-factor authentication code.
    ///   - method: The two-factor authentication method.
    ///   - remember: Whether to remember the two-factor code.
    ///   - captchaToken:  An optional captcha token value to add to the token request.
    ///
    /// - Returns: The account to unlock the vault for.
    ///
    func loginWithTwoFactorCode(
        email: String,
        code: String,
        method: TwoFactorAuthMethod,
        remember: Bool,
        captchaToken: String?
    ) async throws -> Account?

    /// Evaluates the supplied master password against the master password policy provided by the Identity response.
    /// - Parameters:
    ///   - email: user email.
    ///   - masterPassword: user master password.
    ///   - policy: Optional `MasterPasswordPolicyOptions` to check against password.
    /// - Returns: True if the master password does NOT meet any policy requirements, false otherwise
    /// (or if no policy present)
    ///
    func requirePasswordChange(
        email: String,
        masterPassword: String,
        policy: MasterPasswordPolicyOptions?
    ) async throws -> Bool

    /// Resend the email with the user's verification code.
    func resendVerificationCodeEmail() async throws

    /// Sets the pending admin login request for a user ID.
    ///
    /// - Parameters:
    ///   - adminLoginRequest: The user's pending admin login request.
    ///   - userId: The user ID associated with the pending admin login request.
    ///
    func setPendingAdminLoginRequest(_ adminLoginRequest: PendingAdminLoginRequest?, userId: String?) async throws
}

extension AuthService {
    /// Get all the pending login requests.
    ///
    func getPendingLoginRequests() async throws -> [LoginRequest] {
        try await getPendingLoginRequest(withId: nil)
    }
}

// MARK: - DefaultAuthService

/// The default implementation of `AuthService`.
///
class DefaultAuthService: AuthService { // swiftlint:disable:this type_body_length
    // MARK: Properties

    /// The API service used to make calls related to the account process.
    private let accountAPIService: AccountAPIService

    /// The service used by the application to manage the app's ID.
    private let appIdService: AppIdService

    /// The API service used to make calls related to the auth process.
    private let authAPIService: AuthAPIService

    /// The callback url scheme for this application.
    let callbackUrlScheme = "bitwarden"

    /// The client used by the application to handle auth related encryption and decryption tasks.
    private let clientAuth: ClientAuthProtocol

    /// The client used for generating passwords and passphrases.
    private let clientGenerators: ClientGeneratorsProtocol

    /// The client used by the application to handle account fingerprint phrase generation.
    private let clientPlatform: ClientPlatformProtocol

    /// The code verifier used to login after receiving the code from the WebAuth.
    private var codeVerifier = ""

    /// The service used by the application to manage the environment settings.
    private let environmentService: EnvironmentService

    /// The repository used to manages keychain items.
    private let keychainRepository: KeychainRepository

    /// The service used by the application to manage the policy.
    private var policyService: PolicyService

    /// The request model to resend the email with the two-factor verification code.
    private var resendEmailModel: ResendEmailCodeRequestModel?

    /// The single sign on callback url for this application.
    private var singleSignOnCallbackUrl: String { "\(callbackUrlScheme)://sso-callback" }

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The object used by the application to retrieve information about this device.
    private let systemDevice: SystemDevice

    /// The service used by the application to manage trust device information.
    private let trustDeviceService: TrustDeviceService

    /// The two-factor request, which is cached after the original login request fails and then
    /// reused with the code once the user has entered it.
    private var twoFactorRequest: IdentityTokenRequestModel?

    /// The data generated when initiating a login with device request, which is used to
    /// complete the login process after the request is approved.
    private var loginWithDeviceData: AuthRequestResponse?

    // MARK: Initialization

    /// Creates a new `DefaultSingleSignOnService`.
    ///
    /// - Parameters:
    ///   - accountAPIService: The API service used to make calls related to the account process.
    ///   - appIdService: The service used by the application to manage the app's ID.
    ///   - authAPIService: The API service used to make calls related to the auth process.
    ///   - clientAuth: The client used by the application to handle auth related encryption and decryption tasks.
    ///   - clientGenerators: The client used for generating passwords and passphrases.
    ///   - clientPlatform: The client used by the application to handle account fingerprint phrase generation.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - keychainRepository: The repository used to manages keychain items.
    ///   - policyService: The service used by the application to manage the policy.
    ///   - stateService: The object used by the application to retrieve information about this device.
    ///   - systemDevice: The object used by the application to retrieve information about this device.
    ///   - trustDeviceService: The service used by the application to manage trust device information.
    ///
    init(
        accountAPIService: AccountAPIService,
        appIdService: AppIdService,
        authAPIService: AuthAPIService,
        clientAuth: ClientAuthProtocol,
        clientGenerators: ClientGeneratorsProtocol,
        clientPlatform: ClientPlatformProtocol,
        environmentService: EnvironmentService,
        keychainRepository: KeychainRepository,
        policyService: PolicyService,
        stateService: StateService,
        systemDevice: SystemDevice,
        trustDeviceService: TrustDeviceService
    ) {
        self.accountAPIService = accountAPIService
        self.appIdService = appIdService
        self.authAPIService = authAPIService
        self.clientAuth = clientAuth
        self.clientGenerators = clientGenerators
        self.clientPlatform = clientPlatform
        self.environmentService = environmentService
        self.keychainRepository = keychainRepository
        self.policyService = policyService
        self.stateService = stateService
        self.systemDevice = systemDevice
        self.trustDeviceService = trustDeviceService
    }

    // MARK: Methods

    func answerLoginRequest(_ loginRequest: LoginRequest, approve: Bool) async throws {
        let appID = await appIdService.getOrCreateAppId()

        // Encrypt the login request's public key.
        let publicKey = loginRequest.publicKey
        let encodedKey = try await clientAuth.approveAuthRequest(publicKey: publicKey)

        // Send the API request.
        let requestModel = AnswerLoginRequestRequestModel(
            deviceIdentifier: appID,
            key: encodedKey,
            masterPasswordHash: nil,
            requestApproved: approve
        )
        _ = try await authAPIService.answerLoginRequest(loginRequest.id, requestModel: requestModel)
    }

    func checkPendingLoginRequest(withId id: String) async throws -> LoginRequest {
        guard let loginWithDeviceData else { throw AuthError.missingLoginWithDeviceData }

        return try await authAPIService.checkPendingLoginRequest(
            withId: id,
            accessCode: loginWithDeviceData.accessCode
        )
    }

    func denyAllLoginRequests(_ requests: [LoginRequest]) async throws {
        for request in requests {
            try await answerLoginRequest(request, approve: false)
        }
    }

    func generateSingleSignOnUrl(from organizationIdentifier: String) async throws -> (url: URL, state: String) {
        // First pre-validate the organization identifier and get the resulting token.
        let response = try await authAPIService.preValidateSingleSignOn(
            organizationIdentifier: organizationIdentifier
        )

        // Generate a password to send to the single sign on view.
        let passwordSettings = PasswordGeneratorRequest(
            lowercase: true,
            uppercase: true,
            numbers: true,
            special: false,
            length: 64,
            avoidAmbiguous: true,
            minLowercase: 0,
            minUppercase: 0,
            minNumber: 1,
            minSpecial: 0
        )
        codeVerifier = try await clientGenerators.password(settings: passwordSettings)
        let codeChallenge = Data(codeVerifier.utf8)
            .generatedHashBase64Encoded(using: SHA256.self)
            .urlEncoded()

        let state = try await clientGenerators.password(settings: passwordSettings)

        let queryItems = [
            URLQueryItem(name: "client_id", value: Constants.clientType),
            URLQueryItem(name: "redirect_uri", value: singleSignOnCallbackUrl),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "api offline_access"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "response_mode", value: "query"),
            URLQueryItem(name: "domain_hint", value: organizationIdentifier),
            URLQueryItem(name: "ssoToken", value: response.token),
        ]

        // Generate the URL.
        var urlComponents = URLComponents(string: environmentService.identityURL.absoluteString)
        urlComponents?.path.append("/connect/authorize")
        urlComponents?.queryItems = queryItems
        guard let url = urlComponents?.url else { throw AuthError.unableToGenerateSSOUrl }
        return (url, state)
    }

    func getPendingAdminLoginRequest(userId: String?) async throws -> PendingAdminLoginRequest? {
        let activeUserId = try await stateService.getAccountIdOrActiveId(userId: userId)
        do {
            if let jsonString = try await keychainRepository.getPendingAdminLoginRequest(userId: activeUserId),
               let jsonData = jsonString.data(using: .utf8) {
                return try JSONDecoder().decode(PendingAdminLoginRequest.self, from: jsonData)
            }
            return nil
        } catch KeychainServiceError.osStatusError(errSecItemNotFound) {
            return nil
        }
    }

    func getPendingLoginRequest(withId id: String?) async throws -> [LoginRequest] {
        // Get the pending login requests.
        var loginRequests = if let id {
            try await [authAPIService.getPendingLoginRequest(withId: id)]
        } else {
            try await authAPIService.getPendingLoginRequests()
        }

        // Use the user's email to decode the fingerprint phrase for each request.
        let userEmail = try await stateService.getActiveAccount().profile.email
        loginRequests = try await loginRequests.asyncMap { request in
            var request = request
            request.fingerprintPhrase = try await self.getFingerprintPhrase(from: request.publicKey, email: userEmail)
            return request
        }
        return loginRequests
    }

    func hashPassword(password: String, purpose: HashPurpose) async throws -> String {
        let account = try await stateService.getActiveAccount()
        return try await clientAuth.hashPassword(
            email: account.profile.email,
            password: password,
            kdfParams: account.kdf.sdkKdf,
            purpose: purpose
        )
    }

    func initiateLoginWithDevice(
        email: String,
        type: AuthRequestType
    ) async throws -> (authRequestResponse: AuthRequestResponse, requestId: String) {
        // Check for a valid pending admin login request
        if type == AuthRequestType.adminApproval {
            if let savedRequest = try await getPendingAdminLoginRequest(userId: nil),
               let updatedRequest = try await getPendingLoginRequest(withId: savedRequest.id).first,
               updatedRequest.isAnswered == false,
               updatedRequest.isExpired == false {
                let loginData = AuthRequestResponse(
                    privateKey: savedRequest.privateKey,
                    publicKey: savedRequest.publicKey,
                    fingerprint: savedRequest.fingerprint,
                    accessCode: savedRequest.accessCode
                )

                self.loginWithDeviceData = loginData
                // Return existing data to continue waiting for the response
                return (authRequestResponse: loginData, requestId: savedRequest.id)
            } else {
                try await setPendingAdminLoginRequest(nil, userId: nil)
            }
        }

        // Get the app's id.
        let appId = await appIdService.getOrCreateAppId()

        // Initiate the login request and cache the result.
        let loginWithDeviceData = try await clientAuth.newAuthRequest(email: email)
        let loginRequest = try await authAPIService.initiateLoginWithDevice(LoginWithDeviceRequestModel(
            email: email,
            publicKey: loginWithDeviceData.publicKey,
            deviceIdentifier: appId,
            accessCode: loginWithDeviceData.accessCode,
            type: type,
            fingerprintPhrase: loginWithDeviceData.fingerprint
        ))

        self.loginWithDeviceData = loginWithDeviceData

        // Save request for future use if necessary
        if type == AuthRequestType.adminApproval {
            try await setPendingAdminLoginRequest(PendingAdminLoginRequest(
                id: loginRequest.id,
                authRequestResponse: loginWithDeviceData
            ), userId: nil)
        }

        // Return the auth request response and the request id.
        return (
            authRequestResponse: loginWithDeviceData,
            requestId: loginRequest.id
        )
    }

    func loginWithDevice(
        _ loginRequest: LoginRequest,
        email: String,
        isAuthenticated: Bool = false,
        captchaToken: String?
    ) async throws -> (String, String) {
        guard let loginWithDeviceData else { throw AuthError.missingLoginWithDeviceData }
        guard let key = loginRequest.key else { throw AuthError.missingLoginWithDeviceKey }

        if !isAuthenticated {
            // Get the identity token to log in to Bitwarden.
            _ = try await getIdentityTokenResponse(
                authenticationMethod: .password(
                    username: email,
                    password: loginWithDeviceData.accessCode
                ),
                email: email,
                captchaToken: captchaToken,
                loginRequestId: loginRequest.id
            )
        }

        // Return the information necessary to unlock the vault.
        return (loginWithDeviceData.privateKey, key)
    }

    func loginWithMasterPassword(_ masterPassword: String, username: String, captchaToken: String?) async throws {
        // Complete the pre-login steps.
        let response = try await accountAPIService.preLogin(email: username)

        // Get the identity token to log in to Bitwarden.
        let hashedPassword = try await clientAuth.hashPassword(
            email: username,
            password: masterPassword,
            kdfParams: response.sdkKdf,
            purpose: .serverAuthorization
        )
        let token = try await getIdentityTokenResponse(
            authenticationMethod: .password(username: username, password: hashedPassword),
            email: username,
            captchaToken: captchaToken
        )

        // Save the master password hash.
        try await saveMasterPasswordHash(password: masterPassword)

        var policy: MasterPasswordPolicyOptions?
        if let model = token.masterPasswordPolicy {
            policy = MasterPasswordPolicyOptions(
                minComplexity: model.minComplexity ?? 0,
                minLength: model.minLength ?? 0,
                requireUpper: model.requireUpper ?? false,
                requireLower: model.requireLower ?? false,
                requireNumbers: model.requireNumbers ?? false,
                requireSpecial: model.requireSpecial ?? false,
                enforceOnLogin: model.enforceOnLogin ?? false
            )
        }
        if try await requirePasswordChange(email: username, masterPassword: masterPassword, policy: policy) {
            try await stateService.setForcePasswordResetReason(.weakMasterPasswordOnLogin)
        }
    }

    /// Check TDE user decryption options to see if can unlock with trusted deviceKey or needs further actions
    private func canUnlockWithDeviceKey(_ response: IdentityTokenResponseModel) async throws -> Bool {
        if let decryptionOptions = response.userDecryptionOptions,
           let trustedDeviceOption = decryptionOptions.trustedDeviceOption {
            if try await trustDeviceService.isDeviceTrusted() {
                // Server keys were deleted, remove local device as trusted locally
                if trustedDeviceOption.encryptedPrivateKey == nil,
                   trustedDeviceOption.encryptedUserKey == nil {
                    try await trustDeviceService.removeTrustedDevice()
                    throw AuthError.requireDecryptionOptions
                }

                // User need to update password
                if response.forcePasswordReset {
                    throw AuthError.requireUpdatePassword
                }

                // User privileges were elevated and needs to set a password
                if !decryptionOptions.hasMasterPassword,
                   trustedDeviceOption.hasManageResetPasswordPermission {
                    // TODO: PM-7340 Set password reason
                    // try await stateService.setForcePasswordResetReason(
                    // ForcePasswordResetReason.tdeUserWithoutPasswordHasPasswordResetPermission
                    // )
                }
                // Device is trusted and user unlock with device key
                return true
            }

            throw AuthError.requireDecryptionOptions
        }

        if response.userDecryptionOptions?.hasMasterPassword == false,
           response.userDecryptionOptions?.keyConnectorOption == nil {
            throw AuthError.requireSetPassword
        }

        return false
    }

    func loginWithSingleSignOn(code: String, email: String) async throws -> Account? {
        // Get the identity token to log in to Bitwarden.
        let response = try await getIdentityTokenResponse(
            authenticationMethod: .authorizationCode(
                code: code,
                codeVerifier: codeVerifier,
                redirectUri: singleSignOnCallbackUrl
            ),
            email: email
        )

        if try await canUnlockWithDeviceKey(response) {
            return nil
        }

        // Return the account if the vault still needs to be unlocked and nil otherwise.
        // TODO: BIT-1392 Wait for SDK to support unlocking vault for TDE accounts.
        return try await stateService.getActiveAccount()
    }

    func loginWithTwoFactorCode(
        email: String,
        code: String,
        method: TwoFactorAuthMethod,
        remember: Bool,
        captchaToken: String? = nil
    ) async throws -> Account? {
        guard var twoFactorRequest else { throw AuthError.missingTwoFactorRequest }

        // Add the two factor information to the request.
        twoFactorRequest.twoFactorCode = code
        twoFactorRequest.twoFactorMethod = method
        twoFactorRequest.twoFactorRemember = remember

        // Add the captcha result, if applicable.
        if let captchaToken { twoFactorRequest.captchaToken = captchaToken }

        // Get the identity token to log in to Bitwarden.
        let response = try await getIdentityTokenResponse(email: email, request: twoFactorRequest)

        // Save the master password hash.
        if case let .password(_, password) = twoFactorRequest.authenticationMethod {
            try await saveMasterPasswordHash(password: password)
        }

        // Remove the cached request after successfully logging in.
        self.twoFactorRequest = nil
        resendEmailModel = nil

        if try await canUnlockWithDeviceKey(response) {
            return nil
        }

        // Return the account if the vault still needs to be unlocked.
        return try await stateService.getActiveAccount()
    }

    func requirePasswordChange(
        email: String,
        masterPassword: String,
        policy: MasterPasswordPolicyOptions?
    ) async throws -> Bool {
        // Check if we need to change password on login
        guard let masterPasswordPolicy = try await policyService.getMasterPasswordPolicyOptions() ?? policy,
              masterPasswordPolicy.enforceOnLogin else {
            return false
        }

        // Calculate the strength of the user email and password
        let strength = await clientAuth.passwordStrength(
            password: masterPassword,
            email: email,
            additionalInputs: []
        )

        // Check if master password meets the master password policy.
        let satisfyPolicy = await clientAuth.satisfiesPolicy(
            password: masterPassword,
            strength: strength,
            policy: masterPasswordPolicy
        )

        return satisfyPolicy == false
    }

    func resendVerificationCodeEmail() async throws {
        guard let resendEmailModel else { throw AuthError.unableToResendEmail }
        try await authAPIService.resendEmailCode(resendEmailModel)
    }

    func setPendingAdminLoginRequest(_ adminLoginRequest: PendingAdminLoginRequest?, userId: String?) async throws {
        let activeUserId = try await stateService.getAccountIdOrActiveId(userId: userId)
        do {
            if let adminLoginRequest {
                let jsonData = try JSONEncoder().encode(adminLoginRequest)
                guard let jsonString = String(data: jsonData, encoding: .utf8) else { throw AuthError.missingData }
                try await keychainRepository.setPendingAdminLoginRequest(jsonString, userId: activeUserId)
            } else {
                try await keychainRepository.deletePendingAdminLoginRequest(userId: activeUserId)
            }
        } catch KeychainServiceError.osStatusError(errSecItemNotFound) {
            return
        }
    }

    // MARK: Private Methods

    /// Get the fingerprint phrase from the public key of a login request.
    ///
    /// - Parameters:
    ///   - publicKey: The public key of a login request.
    ///   - email: The user's email.
    ///
    /// - Returns: The fingerprint phrase.
    ///
    private func getFingerprintPhrase(from publicKey: String, email: String) async throws -> String {
        try await clientPlatform.fingerprint(req: .init(
            fingerprintMaterial: email,
            publicKey: publicKey.urlDecoded()
        ))
    }

    /// Get an identity token and handle the response.
    ///
    /// - Parameters:
    ///   - authenticationMethod: The authentication method to use.
    ///   - email: The user's email address.
    ///   - captchaToken: The optional captcha token. Defaults to `nil`.
    ///   - request: The cached request, if resending a login request with two-factor codes. Defaults to `nil`.
    ///
    private func getIdentityTokenResponse(
        authenticationMethod: IdentityTokenRequestModel.AuthenticationMethod? = nil,
        email: String,
        captchaToken: String? = nil,
        loginRequestId: String? = nil,
        request: IdentityTokenRequestModel? = nil
    ) async throws -> IdentityTokenResponseModel {
        // Get the app's id.
        let appID = await appIdService.getOrCreateAppId()

        var request = request
        if let authenticationMethod {
            // Use the cached two-factor data, if available.
            let savedTwoFactorToken = await stateService.getTwoFactorToken(email: email)
            let method: TwoFactorAuthMethod? = (savedTwoFactorToken != nil) ? .remember : nil
            let remember: Bool? = (savedTwoFactorToken != nil) ? false : nil

            // Form the token request.
            request = IdentityTokenRequestModel(
                authenticationMethod: authenticationMethod,
                captchaToken: captchaToken,
                deviceInfo: DeviceInfo(
                    identifier: appID,
                    name: systemDevice.modelIdentifier
                ),
                loginRequestId: loginRequestId,
                twoFactorCode: savedTwoFactorToken,
                twoFactorMethod: method,
                twoFactorRemember: remember
            )
        }
        do {
            // Get the identity token from Bitwarden.
            guard let request else { throw AuthError.unableToGenerateRequest }
            let identityTokenResponse = try await authAPIService.getIdentityToken(request)

            // If the user just authenticated with a two-factor code and selected
            // the option to remember, then the API response will return a token
            // that be used in place of the two-factor code on the next login attempt.
            if let twoFactorToken = identityTokenResponse.twoFactorToken {
                await stateService.setTwoFactorToken(twoFactorToken, email: email)
            }

            // Create the account.
            let urls = await stateService.getPreAuthEnvironmentUrls()
            let account = try Account(identityTokenResponseModel: identityTokenResponse, environmentUrls: urls)
            try await saveAccount(account, identityTokenResponse: identityTokenResponse)

            return identityTokenResponse
        } catch let error as IdentityTokenRequestError {
            if case let .twoFactorRequired(_, ssoToken, captchaBypassToken) = error {
                // If the token request require two-factor authentication, cache the request so that
                // the token information can be added once the user inputs the code.
                twoFactorRequest = request
                twoFactorRequest?.captchaToken = captchaBypassToken

                // Form the resend email request in case the user needs to resend the verification code email.
                var passwordHash: String?
                if case let .password(_, password) = request?.authenticationMethod { passwordHash = password }
                resendEmailModel = .init(
                    deviceIdentifier: appID,
                    email: email,
                    masterPasswordHash: passwordHash,
                    ssoEmail2FaSessionToken: ssoToken
                )

                // If this error was thrown, it also means any cached two-factor token is not valid.
                await stateService.setTwoFactorToken(nil, email: email)
            }
            // Re-throw the error.
            throw error
        }
    }

    /// Saves the user's account information.
    ///
    /// - Parameters:
    ///   - account: The user's account.
    ///   - identityTokenResponse: The response from the identity token request.
    ///
    private func saveAccount(_ account: Account, identityTokenResponse: IdentityTokenResponseModel) async throws {
        await stateService.addAccount(account)

        // Save the encryption keys.
        if let encryptionKeys = AccountEncryptionKeys(identityTokenResponseModel: identityTokenResponse) {
            try await stateService.setAccountEncryptionKeys(encryptionKeys)
        }

        // Save the account tokens.
        try await keychainRepository.setAccessToken(
            identityTokenResponse.accessToken,
            userId: account.profile.userId
        )
        try await keychainRepository.setRefreshToken(
            identityTokenResponse.refreshToken,
            userId: account.profile.userId
        )
    }

    /// Saves the user's master password hash.
    ///
    /// - Parameter password: The user's master password to hash and save.
    ///
    private func saveMasterPasswordHash(password: String) async throws {
        try await stateService.setMasterPasswordHash(hashPassword(
            password: password,
            purpose: .localAuthorization
        ))
    }
} // swiftlint:disable:this file_length
