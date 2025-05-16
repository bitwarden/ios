import Foundation

public extension URL {
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

    /// Returns a string of the URL with the scheme removed (e.g. `send.bitwarden.com/39ngaol3`).
    var withoutScheme: String {
        guard let scheme else { return absoluteString }
        let prefix = "\(scheme)://"
        guard absoluteString.hasPrefix(prefix) else { return absoluteString }
        return String(absoluteString.dropFirst(prefix.count))
    }
}
