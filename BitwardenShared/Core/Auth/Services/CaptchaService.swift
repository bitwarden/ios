import BitwardenKit
import BitwardenResources
import Foundation

// MARK: - CaptchaURLError

/// A set of errors that could occur when generating a captcha url.
///
enum CaptchaURLError: Error {
    /// The captca request was unable to be encoded for use in the captca url.
    case unableToEncodeRequest

    /// The callback url scheme was unable to be encoded for use in the captca url.
    case unableToEncodeCallbackUrlScheme

    /// The url was unable to be generated.
    case unableToGenerateUrl
}

// MARK: - CaptchaService

/// A protocol for a service used to generate artifacts that are necessary for proceeding through the captcha flow.
protocol CaptchaService {
    /// The callback url scheme for this application.
    var callbackUrlScheme: String { get }

    /// Generates a url for use when proceeding through the captcha flow.
    ///
    /// - Parameter siteKey: The token to authenticate the captcha request with.
    /// - Returns: The url to use when opening the captcha flow.
    /// - Throws: Throws a `CaptchaURLError` if an error occurs during generation.
    ///
    func generateCaptchaUrl(with siteKey: String) throws -> URL
}

// MARK: - DefaultCaptchaService

/// The default implementation of `CaptchaService`.
///
class DefaultCaptchaService: CaptchaService {
    // MARK: Properties

    /// The callback url scheme.
    let callbackUrlScheme: String

    /// The service used by the application to manage the environment settings.
    private let environmentService: EnvironmentService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    // MARK: Initialization

    /// Creates a new `DefaultCaptchaService`.
    ///
    /// - Parameters:
    ///   - environmentService: The service used by the application to manage the environment settings.
    ///   - stateService: The service used by the application to manage account state.
    ///
    init(
        environmentService: EnvironmentService,
        stateService: StateService
    ) {
        self.environmentService = environmentService
        self.stateService = stateService
        callbackUrlScheme = "bitwarden"
    }

    // MARK: Methods

    func generateCaptchaUrl(with siteKey: String) throws -> URL {
        let callbackUrl = "\(callbackUrlScheme)://captcha-callback"
        let locale = stateService.appLanguage.value ?? Locale.current.identifier
        let request = CaptchaRequestModel(
            callbackUri: callbackUrl,
            captchaRequiredText: Localizations.captchaRequired,
            locale: locale,
            siteKey: siteKey
        )

        guard let requestEncoded = try request
            .encode()
            .base64EncodedString()
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { throw CaptchaURLError.unableToEncodeRequest }

        guard let callbackUrlEncoded = callbackUrl
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { throw CaptchaURLError.unableToEncodeCallbackUrlScheme }

        let queryItems = [
            URLQueryItem(name: "data", value: requestEncoded),
            URLQueryItem(name: "parent", value: callbackUrlEncoded),
            URLQueryItem(name: "v", value: "1"),
        ]

        guard let url = environmentService.webVaultURL
            .appendingPathComponent("/captcha-mobile-connector.html")
            .appending(queryItems: queryItems)
        else { throw CaptchaURLError.unableToGenerateUrl }

        return url
    }
}
