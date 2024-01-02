import Foundation

/// A protocol for an instance that describes a HTTP response.
///
public protocol Response {
    /// Initialize a `Response` from a `HTTPResponse`.
    ///
    /// Typically, this is where the raw `HTTPResponse` would be decoded into an app model.
    ///
    /// - Parameter response: The `HTTPResponse` used to initialize the `Response`.
    ///
    init(response: HTTPResponse) throws
}

/// A protocol for a `Response` containing JSON.
///
public protocol JSONResponse: Response, Codable {
    /// A JSON decoder used to decode this response.
    static var decoder: JSONDecoder { get }
}

public extension JSONResponse {
    /// Initialize a `JSONResponse` from a `HTTPResponse`.
    ///
    /// - Parameter response: The `HTTPResponse` used to initialize the `Response.
    ///
    init(response: HTTPResponse) throws {
        self = try Self.decoder.decode(Self.self, from: response.body)
    }
}

extension Array: Response where Element: JSONResponse {}
extension Array: JSONResponse where Element: JSONResponse {
    public static var decoder: JSONDecoder {
        Element.decoder
    }
}

/// A response for a request when the API returns no data.
///
public struct EmptyResponse: Response {
    public init(response _: HTTPResponse) throws {
        // No-op: Empty or ignored response so there's nothing to parse.
    }
}
