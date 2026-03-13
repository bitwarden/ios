import Foundation

/// A `URLSessionTaskDelegate` that prevents `URLSession` from automatically following HTTP
/// redirects, ensuring that 302 responses are surfaced to response handlers rather than being
/// silently resolved by the networking stack.
final class NoRedirectSessionDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void,
    ) {
        // So far we only need 302 redirection to be surfaced and handled manually.
        if response.statusCode == 302 {
            completionHandler(nil)
        } else {
            completionHandler(request)
        }
    }
}
