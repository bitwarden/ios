import Foundation

/// An object that provides a base url for other services.
///
protocol BaseUrlService: AnyObject {
    /// The base url that all requests should be routed to.
    ///
    var baseUrl: URL { get set }
}

// MARK: - DefaultBaseUrlService

/// The default implementation of `BaseUrlService`.
///
class DefaultBaseUrlService: BaseUrlService {
    // MARK: Properties

    var baseUrl: URL

    // MARK: Initialization

    /// Creates a new `DefaultBaseUrlService`.
    ///
    /// - Parameter baseUrl: The base url that all requests should be routed to.
    init(baseUrl: URL) {
        self.baseUrl = baseUrl
    }
}
