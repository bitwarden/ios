import BitwardenSdk
import Foundation

/// A helper class to retrieve icon images for login items.
enum IconImageHelper {
    // MARK: Static Methods

    /// Retrieves an icon image URL for a given login view.
    ///
    /// This method iterates through the URIs associated with a login view. It attempts to construct
    /// a URL to an icon image for each URI. The first successfully constructed URL is returned.
    ///
    /// - Parameters:
    ///   - loginView: The `LoginView` containing the URIs to process.
    ///   - baseIconUrl: A base URL to use when constructing icon image URLs.
    ///
    /// - Returns: A URL to an icon image if one can be constructed; otherwise, nil.
    static func getIconImage(for loginView: BitwardenSdk.LoginView, from baseIconUrl: URL) -> URL? {
        guard let uris = loginView.uris else {
            return nil
        }

        for uriView in uris {
            if let uri = uriView.uri, let iconUrl = getIconUrl(from: uri, iconsBaseURL: baseIconUrl) {
                return iconUrl
            }
        }

        return nil
    }

    /// Constructs an icon image URL from a given URI string.
    ///
    /// If the URI is a valid website URL, this method constructs a URL to an icon image
    /// based on the website's hostname.
    ///
    /// - Parameters:
    ///   - uri: The URI string to process.
    ///   - iconsBaseURL: A base URL for constructing the icon image URL.
    ///
    /// - Returns: A URL to an icon image if the URI is a valid website; otherwise, nil.
    private static func getIconUrl(from uri: String, iconsBaseURL: URL) -> URL? {
        var hostnameUri = uri

        guard hostnameUri.contains(".") else {
            return nil
        }

        if !hostnameUri.contains("://") {
            hostnameUri = "http://\(hostnameUri)"
        }

        let isWebsite = hostnameUri.starts(with: "http")
        if isWebsite,
           let hostname = getHostname(from: hostnameUri) {
            let baseURLString = iconsBaseURL.absoluteString
            return URL(string: "\(baseURLString)/\(hostname)/icon.png")
        }

        return nil
    }

    /// Extracts the hostname from a given URI string.
    ///
    /// - Parameter uriString: The URI string to extract the hostname from.
    /// - Returns: The hostname if it can be extracted; otherwise, nil.
    private static func getHostname(from uriString: String) -> String? {
        guard let url = URL(string: uriString), let host = url.host else {
            return nil
        }
        return host
    }
}
