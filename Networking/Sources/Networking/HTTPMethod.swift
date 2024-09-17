/// A type representing the HTTP method.
///
public struct HTTPMethod: Equatable, Sendable {
    /// The string value of the method.
    let rawValue: String
}

public extension HTTPMethod {
    /// The `GET` method.
    static let get = HTTPMethod(rawValue: "GET")

    /// The `POST` method.
    static let post = HTTPMethod(rawValue: "POST")

    /// The `PUT` method.
    static let put = HTTPMethod(rawValue: "PUT")

    /// The `DELETE` method.
    static let delete = HTTPMethod(rawValue: "DELETE")

    /// The `PATCH` method.
    static let patch = HTTPMethod(rawValue: "PATCH")
}
