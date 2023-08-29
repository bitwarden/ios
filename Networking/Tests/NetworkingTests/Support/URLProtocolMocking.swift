import Foundation

/// An object that manages mock responses for `MockURLProtocol`.
///
class URLProtocolMocking {
    typealias Response = Result<(URLResponse, Data), Error>

    // MARK: Properties

    /// The singleton mocking instance. Only one object should be used at a time since only one
    /// URL protocol can be registered at a time.
    private static let shared = URLProtocolMocking()

    // MARK: Private properties

    /// The queue used to synchronize access to the instance across threads.
    private let queue = DispatchQueue(label: "URLProtocolMocking")

    /// The responses currently configured for mocking, by URL.
    private var responses: [URL: Response] = [:]

    // MARK: Static Methods

    /// Stub out requests for the given url with a fake response.
    ///
    /// - Parameters:
    ///   - url: The url which will be matched against incoming requests.
    ///   - response: The mock response to return when a request is made.
    ///
    static func mock(_ url: URL, with response: Response) {
        shared.mock(url, with: response)
    }

    /// Resets all mocks on the singleton instance.
    ///
    /// Use this during tearDown() to remove all previously configured mocks.
    ///
    static func reset() {
        shared.reset()
    }

    /// Returns the mocked response for the given url.
    ///
    /// - Parameter url: The url of an incoming request.
    /// - Returns: A response result to use for mocking or nil if the url is not matched.
    ///
    static func response(for url: URL) -> Response? {
        shared.response(for: url)
    }

    // MARK: Private

    /// Stub out requests for the given url with a fake response.
    ///
    /// - Parameters:
    ///   - url: The url which will be matched against incoming requests.
    ///   - response: The mock response to return when a request is made.
    ///
    private func mock(_ url: URL, with response: Response) {
        queue.sync {
            responses[url] = response
        }
    }

    /// Resets all mocks.
    ///
    /// Use this during tearDown() to remove all previously configured mocks.
    ///
    private func reset() {
        queue.sync {
            responses.removeAll()
        }
    }

    /// Returns the mocked response for the given url.
    ///
    /// - Parameter url: The url of an incoming request.
    /// - Returns: A response result to use for mocking or nil if the url is not matched.
    ///
    private func response(for url: URL) -> Response? {
        queue.sync {
            responses[url]
        }
    }
}
