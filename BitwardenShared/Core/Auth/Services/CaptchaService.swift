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
    // MARK: Private Properties

    /// The base url for all requests in this service.
    private let baseUrl: URL

    // MARK: Properties

    let callbackUrlScheme: String

    // MARK: Initialization

    /// Creates a new `DefaultCaptchaService`.
    ///
    /// - Parameters:
    ///   - baseUrl: The base url for all requests in this service.
    ///   - callbackUrlScheme: The callback url scheme for this application. E.g. `"bitwarden"`.
    init(baseUrl: URL, callbackUrlScheme: String) {
        self.baseUrl = baseUrl
        self.callbackUrlScheme = callbackUrlScheme
    }

    // MARK: Methods

    func generateCaptchaUrl(with siteKey: String) throws -> URL {
        let callbackUrl = "\(callbackUrlScheme)://captcha-callback"
        let request = CaptchaRequestModel(
            siteKey: siteKey,
            locale: "en",
            callbackUri: callbackUrl,
            captchaRequiredText: Localizations.captchaRequired
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

        // Using URLComponents until iOS 16 is our base, since that's when `.appending(queryItems:)` was added
        var components = URLComponents(
            url: baseUrl.appendingPathComponent("/captcha-mobile-connector.html"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = queryItems

        guard let url = components?.url else { throw CaptchaURLError.unableToGenerateUrl }

        return url
    }
}
