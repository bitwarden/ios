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
}
