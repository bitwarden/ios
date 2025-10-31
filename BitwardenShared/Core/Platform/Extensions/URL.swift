import BitwardenKit
import Foundation

extension URL {
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
        if host == "localhost" || isIPAddress {
            return host
        }
        return DomainName.parseBaseDomain(url: self) ?? host
    }

    /// Whether the URL has valid components that are in the correct order.
    var hasValidURLComponents: Bool {
        guard absoluteString.isValidURL else { return false }
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
}
