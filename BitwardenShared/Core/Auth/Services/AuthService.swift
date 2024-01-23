import BitwardenSdk
import CryptoKit
import Foundation

// MARK: - AuthServiceError

/// A set of errors that could occur during authentication.
///
enum AuthError: Error {
    /// The request that should have been cached for the two-factor authentication method was missing.
    case missingTwoFactorRequest

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

    /// Generates a url for use when proceeding through the single sign on flow flow.
    ///
    /// - Parameter organizationIdentifier: The organization identifier.
    ///
    /// - Returns: The url to use when opening the single sign on flow and the state that the
    ///   auth result will have to match.
    ///
    func generateSingleSignOnUrl(from organizationIdentifier: String) async throws -> (url: URL, state: String)

    /// Get all the pending login requests.
    ///
    func getPendingLoginRequests() async throws -> [LoginRequest]

    /// Creates a hash value for the user's master password.
    ///
    /// - Parameters:
    ///   - password: The password text to hash.
    ///   - purpose: The purpose of the hash.
    ///
    /// - Returns: A hash value of the password.
    ///
    func hashPassword(password: String, purpose: HashPurpose) async throws -> String

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
    ) async throws -> Account

    /// Resend the email with the user's verification code.
    func resendVerificationCodeEmail() async throws
}

// MARK: - DefaultAuthService

/// The default implementation of `AuthService`.
///
class DefaultAuthService: AuthService {
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

    /// The request model to resend the email with the two-factor verification code.
    private var resendEmailModel: ResendEmailCodeRequestModel?

    /// The single sign on callback url for this application.
    private var singleSignOnCallbackUrl: String { "\(callbackUrlScheme)://sso-callback" }

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The object used by the application to retrieve information about this device.
    private let systemDevice: SystemDevice

    /// The two-factor request, which is cached after the original login request fails and then
    /// reused with the code once the user has entered it.
    private var twoFactorRequest: IdentityTokenRequestModel?

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
    ///   - stateService: The object used by the application to retrieve information about this device.
    ///   - systemDevice: The object used by the application to retrieve information about this device.
    ///
    init(
        accountAPIService: AccountAPIService,
        appIdService: AppIdService,
        authAPIService: AuthAPIService,
        clientAuth: ClientAuthProtocol,
        clientGenerators: ClientGeneratorsProtocol,
        clientPlatform: ClientPlatformProtocol,
        environmentService: EnvironmentService,
        stateService: StateService,
        systemDevice: SystemDevice
    ) {
        self.accountAPIService = accountAPIService
        self.appIdService = appIdService
        self.authAPIService = authAPIService
        self.clientAuth = clientAuth
        self.clientGenerators = clientGenerators
        self.clientPlatform = clientPlatform
        self.environmentService = environmentService
        self.stateService = stateService
        self.systemDevice = systemDevice
    }

    // MARK: Methods

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

    func getPendingLoginRequests() async throws -> [LoginRequest] {
        // Get the pending login requests.
        var loginRequests = try await authAPIService.getPendingLoginRequests()

        // Use the user's email to decode the fingerprint phrase for each request.
        let userEmail = try await stateService.getActiveAccount().profile.email
        loginRequests = try await loginRequests.asyncMap { request in
            var request = request
            request.fingerprintPhrase = try await self.getFingerprintPhrase(from: request.publicKey, email: userEmail)
            return request
        }
        return loginRequests
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
        try await getIdentityTokenResponse(
            authenticationMethod: .password(
                username: username,
                password: hashedPassword
            ),
            email: username,
            captchaToken: captchaToken
        )

        // Save the master password.
        try await stateService.setMasterPasswordHash(hashPassword(
            password: masterPassword,
            purpose: .localAuthorization
        ))
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

    func loginWithSingleSignOn(code: String, email: String) async throws -> Account? {
        // Get the identity token to log in to Bitwarden.
        try await getIdentityTokenResponse(
            authenticationMethod: .authorizationCode(
                code: code,
                codeVerifier: codeVerifier,
                redirectUri: singleSignOnCallbackUrl
            ),
            email: email
        )

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
    ) async throws -> Account {
        guard var twoFactorRequest else { throw AuthError.missingTwoFactorRequest }

        // Add the two factor information to the request.
        twoFactorRequest.twoFactorCode = code
        twoFactorRequest.twoFactorMethod = method
        twoFactorRequest.twoFactorRemember = remember

        // Add the captcha result, if applicable.
        if let captchaToken { twoFactorRequest.captchaToken = captchaToken }

        // Get the identity token to log in to Bitwarden.
        try await getIdentityTokenResponse(email: email, request: twoFactorRequest)

        // Remove the cached request after successfully logging in.
        self.twoFactorRequest = nil
        resendEmailModel = nil

        // Return the account if the vault still needs to be unlocked.
        return try await stateService.getActiveAccount()
    }

    func resendVerificationCodeEmail() async throws {
        guard let resendEmailModel else { throw AuthError.unableToResendEmail }
        try await authAPIService.resendEmailCode(resendEmailModel)
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
        request: IdentityTokenRequestModel? = nil
    ) async throws {
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
            await stateService.addAccount(account)

            // Save the encryption keys.
            let encryptionKeys = AccountEncryptionKeys(identityTokenResponseModel: identityTokenResponse)
            try await stateService.setAccountEncryptionKeys(encryptionKeys)
        } catch let error as IdentityTokenRequestError {
            if case let .twoFactorRequired(_, ssoToken, captchaBypassToken) = error {
                // If the token request require two-factor authentication, cache the request so that
                // the token information can be added once the user inputs the code.
                twoFactorRequest = request
                twoFactorRequest?.captchaToken = captchaBypassToken

                // Form the resend email request in case the user needs to resend the verification code email.
                var passwordHash: String?
                if case let .password(_, password) = authenticationMethod { passwordHash = password }
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
} // swiftlint:disable:this file_length
