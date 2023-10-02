import Foundation

extension URL {
    /// Creates a new `URL` appending the provided query items to the url.
    ///
    /// On iOS 16+, this method uses the method with the same name in Foundation. On iOS 15, this method
    /// uses `URLComponents` to add the query items to the new url.
    ///
    /// - Parameter queryItems: A list of `URLQueryItem`s to add to this url.
    /// - Returns: A new `URL` with the query items appended.
    ///
    func appending(queryItems: [URLQueryItem]) -> URL? {
        if #available(iOS 16, *) {
            // Set this variable to a non-optional `URL` type so that we are calling the function in Foundation,
            // rather than recursively calling this method.
            let url: URL = appending(queryItems: queryItems)
            return url
        } else {
            guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
            else { return nil }

            components.queryItems = queryItems
            return components.url
        }
    }
}
