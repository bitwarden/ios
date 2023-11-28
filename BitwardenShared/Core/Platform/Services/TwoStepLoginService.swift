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
        // Using .appendingPathComponent here would percent encode the '#'
        URL(string: baseUrlService.baseUrl.absoluteString + "/#/settings") ?? baseUrlService.baseUrl
    }
}
