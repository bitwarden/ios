import Foundation

extension URL {
    // MARK: Private Properties

    /// A regular expression that matches IP addresses.
    private var ipRegex: String {
        "^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\." +
            "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\." +
            "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\." +
            "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
    }

    /// Valid top-level domain values.
    private var validTlds: [String] {
        [
            ".com",
            ".net",
            ".org",
            ".edu",
            ".uk",
            ".gov",
            ".ca",
            ".de",
            ".jp",
            ".fr",
            ".au",
            ".ru",
            ".ch",
            ".io",
            ".es",
            ".us",
            ".co",
            ".xyz",
            ".info",
            ".ly",
            ".mil",
        ]
    }

    // MARK: Properties

    /// If the URL is for an app using the Bitwarden `iosapp://` URL scheme, this returns the web
    /// URL after the custom URL scheme.
    var appWebURL: URL? {
        guard isApp else { return nil }
        let webURL = absoluteString.replacingOccurrences(of: Constants.iOSAppProtocol, with: "", options: .anchored)
        return URL(string: webURL)?.sanitized
    }

    /// Returns the URL's domain constructed from the top-level and second-level domain.
    var domain: String? {
        let isIpAddress = host?.range(of: ipRegex, options: .regularExpression) != nil
        if host == "localhost" || isIpAddress {
            return host
        }
        return DomainName.parseBaseDomain(url: self) ?? host
    }

    /// Whether the URL's domain ends in an accepted top-level domain value.
    var hasValidTld: Bool {
        guard let host else { return false }

        for tld in validTlds where host.hasSuffix(tld) {
            return true
        }
        return false
    }

    /// Whether the URL has valid components that are in the correct order.
    var hasValidURLComponents: Bool {
        guard absoluteString.isValidURL, hasValidTld else { return false }
        let scheme = scheme ?? ""
        let host = host ?? ""

        let urlString = "\(scheme)" + "://" + "\(host)"
        return absoluteString.hasPrefix(urlString)
    }

    /// Returns the URL's host with a port, if one exists.
    var hostWithPort: String? {
        guard let host else { return nil }
        return if let port {
            "\(host):\(port)"
        } else {
            host
        }
    }

    /// Determines if the URI is an app with the Bitwarden `iosapp://` URL scheme.
    var isApp: Bool {
        absoluteString.starts(with: Constants.iOSAppProtocol)
    }

    /// Returns a sanitized version of the URL. This will add a https scheme to the URL if the
    /// scheme is missing and remove a trailing slash.
    var sanitized: URL {
        let stringUrl = if absoluteString.hasSuffix("/") {
            String(absoluteString.dropLast())
        } else {
            absoluteString
        }

        guard stringUrl.starts(with: "https://") || stringUrl.starts(with: "http://") else {
            return URL(string: "https://" + stringUrl) ?? self
        }
        return URL(string: stringUrl) ?? self
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
}
