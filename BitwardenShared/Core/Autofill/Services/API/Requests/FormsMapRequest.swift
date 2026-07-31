import Networking

// MARK: - FormsMapRequest

/// A networking request to fetch a versioned Forms Map from the map-the-web repository.
///
struct FormsMapRequest: Request {
    typealias Response = FormsMapResponseModel

    // MARK: Properties

    /// The filename of the forms map artifact (e.g. `"forms.v1.json"`).
    let filename: String

    /// The HTTP method for this request.
    var method: HTTPMethod { .get }

    /// The URL path for this request.
    var path: String { "/\(filename)" }
}
