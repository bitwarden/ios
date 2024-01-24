import Foundation
import Networking

// MARK: - AzureFileUploadRequest

/// A request for uploading a file to an Azure environment.
///
struct AzureFileUploadRequest: Request {
    // MARK: Types

    typealias Response = EmptyResponse

    // MARK: Properties

    /// The body of the request.
    let body: Data?

    /// A dictionary of HTTP headers to be sent in the request.
    let headers: [String: String]

    /// A concrete `HTTPRequest` representation of this request.
    var httpRequest: HTTPRequest {
        HTTPRequest(
            url: url,
            method: method,
            headers: headers,
            body: body
        )
    }

    /// The HTTP method for the request.
    let method: HTTPMethod = .put

    /// The path for this request. Intentionally empty since this request uses a custom URL.
    let path = ""

    /// The custom URL for this request. Used in place of `path`, since file uploads to Azure can be
    /// uploaded to an arbitrary Azure URL.
    let url: URL

    // MARK: Initialization

    /// Creates a new `AzureFileUploadRequest`.
    ///
    /// - Parameters:
    ///   - data: The data representation of the file.
    ///   - date: The date this request is being sent.
    ///   - url: The custom URL for this request.
    ///
    init(data: Data, date: Date = .now, url: URL) {
        body = data
        self.url = url

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss z"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let formattedDate = dateFormatter.string(from: date)

        let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let version = urlComponents?.queryItems?.first(where: { $0.name == "sv" })?.value

        headers = [
            "x-ms-date": formattedDate,
            "x-ms-version": version ?? "",
            "x-ms-blob-type": "BlockBlob",
            "Content-Length": "\(data.count)",
        ]
    }
}
