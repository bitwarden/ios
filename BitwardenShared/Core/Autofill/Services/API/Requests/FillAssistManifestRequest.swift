import Networking

// MARK: - FillAssistManifestRequest

/// A networking request to fetch the Fill-Assist manifest from the map-the-web repository.
///
struct FillAssistManifestRequest: Request {
    typealias Response = FillAssistManifestResponseModel

    // MARK: Properties

    /// The HTTP method for this request.
    var method: HTTPMethod { .get }

    /// The URL path for this request.
    var path: String { "/manifest.json" }
}
