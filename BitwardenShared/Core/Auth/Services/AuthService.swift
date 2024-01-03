import BitwardenSdk
import CryptoKit
import Foundation

// MARK: - AuthServiceError

/// A set of errors that could occur during authentication.
///
enum AuthError: Error {
    /// There was a problem extracting the code from the single sign on WebAuth response.
    case unableToDecodeSSOResponse

    /// There was a problem generating the single sign on code challenge.
    case unableToGenerateSSOCodeChallenge

    /// There was a problem generating the single sign on url.
    case unableToGenerateSSOUrl
}

// MARK: - AuthService

/// A protocol for a service used that handles the auth logic.
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
    func generateSingleSignOnUrl(from organizationIdentifier: String) async throws -> (URL, String)

    /// Login with the single sign on code.
    ///
    /// - Parameter code: The code received from the single sign on WebAuth flow.
    /// - Returns: An account for which to unlock the vault, or nil if the vault does not need to be unlocked.
    ///
    func loginSingleSignOn(code: String) async throws -> Account?
}

// MARK: - DefaultAuthService

/// The default implementation of `AuthService`.
///
class DefaultAuthService: AuthService {
    // MARK: Properties

    /// The service used by the application to manage the app's ID.
    let appIdService: AppIdService

    /// The API service used to make calls related to the auth process.
    private let authAPIService: AuthAPIService

    /// The callback url scheme for this application.
    let callbackUrlScheme = "bitwarden"

    /// The client used for generating passwords and passphrases.
    private let clientGenerators: ClientGeneratorsProtocol

    /// The code verifier used to login after receiving the code from the WebAuth.
    private var codeVerifier = ""

    /// The service used by the application to manage the environment settings.
    private let environmentService: EnvironmentService

    /// The single sign on callback url for this application.
    private var singleSignOnCallbackUrl: String { "\(callbackUrlScheme)://sso-callback" }

    /// The service used by the application to manage account state.
    private let stateService: StateService

    /// The object used by the application to retrieve information about this device.
    private let systemDevice: SystemDevice

    // MARK: Initialization

    /// Creates a new `DefaultSingleSignOnService`.
    ///
    /// - Parameters:
    ///   - appIdService: The service used by the application to manage the app's ID.
    ///   - authAPIService: The API service used to make calls related to the auth process.
    ///   - clientGenerators: The client used for generating passwords and passphrases.
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - stateService: The object used by the application to retrieve information about this device.
    ///   - systemDevice: The object used by the application to retrieve information about this device.
    ///
    init(
        appIdService: AppIdService,
        authAPIService: AuthAPIService,
        clientGenerators: ClientGeneratorsProtocol,
        environmentService: EnvironmentService,
        stateService: StateService,
        systemDevice: SystemDevice
    ) {
        self.appIdService = appIdService
        self.authAPIService = authAPIService
        self.clientGenerators = clientGenerators
        self.environmentService = environmentService
        self.stateService = stateService
        self.systemDevice = systemDevice
    }

    // MARK: Methods

    func generateSingleSignOnUrl(from organizationIdentifier: String) async throws -> (URL, String) {
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
        guard let codeChallenge = codeVerifier.data(using: .utf8)?
            .generatedHashBase64Encoded(using: SHA256.self)
            .urlEncoded()
        else { throw AuthError.unableToGenerateSSOCodeChallenge }

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

    func loginSingleSignOn(code: String) async throws -> Account? {
        // Get the app's id.
        let appID = await appIdService.getOrCreateAppId()

        // Get the identity token from Bitwarden.
        let identityTokenRequest = IdentityTokenRequestModel(
            authenticationMethod: .authorizationCode(
                code: code,
                codeVerifier: codeVerifier,
                redirectUri: singleSignOnCallbackUrl
            ),
            captchaToken: nil,
            deviceInfo: DeviceInfo(
                identifier: appID,
                name: systemDevice.modelIdentifier
            )
        )
        let identityTokenResponse = try await authAPIService.getIdentityToken(identityTokenRequest)

        // Create the account.
        let urls = await stateService.getPreAuthEnvironmentUrls()
        let account = try Account(identityTokenResponseModel: identityTokenResponse, environmentUrls: urls)
        await stateService.addAccount(account)

        // Save the encryption keys.
        let encryptionKeys = AccountEncryptionKeys(identityTokenResponseModel: identityTokenResponse)
        try await stateService.setAccountEncryptionKeys(encryptionKeys)

        // Return the account if the vault still needs to be unlocked and nil otherwise.
        // TODO: - Wait for SDK to support unlocking vault for TDE accounts.
        return account
    }
}
