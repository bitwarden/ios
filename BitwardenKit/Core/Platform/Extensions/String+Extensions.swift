import Foundation

/// Extension helpers for `String`.
public extension String {
    /// Tries to convert the string to an `URL`, if it can't then it tries to fix it by adding
    /// a http scheme prefix if it's an IP address or https scheme prefix in any other case.
    /// - Returns: The same `String` if it can be converted to an `URL` or the fixed
    /// `String` otherwise.
    func fixURLIfNeeded() -> String {
        if URL(string: self) != nil {
            return self
        }

        if let url = URL(string: "http://\(self)"), url.isIPAddress {
            return url.absoluteString
        }

        if !hasPrefix("http") {
            return "https://\(self)"
        }

        return self
    }
}
