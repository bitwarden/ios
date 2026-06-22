import Networking

// MARK: - FormsMapRequest

/// A networking request to fetch the Forms Map from the map-the-web repository.
///
struct FormsMapRequest: Request {
    typealias Response = FormsMapResponseModel

    // MARK: Properties

    /// The HTTP method for this request.
    var method: HTTPMethod { .get }

    /// The URL path for this request.
    var path: String { "/forms.v0.json" }
}
