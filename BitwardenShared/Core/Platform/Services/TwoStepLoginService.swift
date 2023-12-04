import Foundation

/// A protocol for a `TwoStepLoginService` which is used by the application to generate a two step login URL.
///
protocol TwoStepLoginService: AnyObject {
    /// Generates the two step login URL.
    ///
    /// - Returns: The two step login URL.
    ///
    func twoStepLoginUrl() -> URL
}

// MARK: - DefaultTwoStepLoginService

/// The default implementation of `TwoStepLoginService`.
///
class DefaultTwoStepLoginService: TwoStepLoginService {
    // MARK: Properties

    /// A service for retrieving the base url for all requests in this service.
    let baseUrlService: BaseUrlService

    // MARK: Initialization

    /// Creates a new `DefaultTwoStepLoginService`.
    ///
    /// - Parameters:
    ///   - baseUrl: The base url for all requests in this service.
    ///
    init(baseUrlService: BaseUrlService) {
        self.baseUrlService = baseUrlService
    }

    // MARK: Methods

    func twoStepLoginUrl() -> URL {
        // Foundation's URL appending methods percent encode the path component that is passed into the method,
        // which includes the `#` symbol. Since the `#` character is a critical portion of this url, we use String
        // concatenation to get around this limitation. If for some reason this URL creation fails, we pass back the
        // base url for this user. This should take them to the web app regardless,
        // and they can navigate to the settings page from there.
        URL(string: baseUrlService.baseUrl.absoluteString + "/#/settings") ?? baseUrlService.baseUrl
    }
}
