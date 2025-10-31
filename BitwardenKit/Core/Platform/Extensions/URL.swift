import Foundation

public extension URL {
    // MARK: Private Properties

    /// A regular expression that matches IP addresses.
    private var ipRegex: String {
        "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\." +
            "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\." +
            "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\." +
            "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    }

    // MARK: Properties

    /// Determines if the URI is an IP address.
    var isIPAddress: Bool {
        host?.range(of: ipRegex, options: .regularExpression) != nil
    }

    /// Returns a sanitized version of the URL. This will add a https scheme to the URL if the
    /// scheme is missing and remove a trailing slash.
    var sanitized: URL {
        URL(string: absoluteString.httpsNormalized()) ?? self
    }

    /// Returns a string of the URL with the scheme removed (e.g. `send.bitwarden.com/39ngaol3`).
    var withoutScheme: String {
        guard let scheme else { return absoluteString }
        let prefix = "\(scheme)://"
        guard absoluteString.hasPrefix(prefix) else { return absoluteString }
        return String(absoluteString.dropFirst(prefix.count))
    }

    // MARK: Methods

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

    /// Sets whether the file should be excluded from backups.
    ///
    /// - Parameter value: `true` if the file should be excluded from backups, or `false` otherwise.
    ///
    func setIsExcludedFromBackup(_ value: Bool) throws {
        var url = self
        var values = URLResourceValues()
        values.isExcludedFromBackup = value
        try url.setResourceValues(values)
    }
}
