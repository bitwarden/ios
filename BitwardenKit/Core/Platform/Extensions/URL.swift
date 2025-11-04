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
}
