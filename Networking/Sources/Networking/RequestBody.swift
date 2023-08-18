import Foundation

/// A protocol for an instance containing the data for the body of a request.
///
public protocol RequestBody {
    /// Additional headers to append to the request headers.
    var additionalHeaders: [String: String] { get }

    /// Encodes the data to be included in the body of the request.
    ///
    /// - Returns: The encoded data to include in the body of the request.
    ///
    func encode() throws -> Data
}

/// A protocol for a `RequestBody` that can be encoded to JSON for the body of a request.
///
public protocol JSONRequestBody: RequestBody, Encodable {
    /// The `JSONEncoder` used to encode the object to include in the body of the request.
    static var encoder: JSONEncoder { get }
}

public extension JSONRequestBody {
    /// Additional headers to append to the request headers.
    var additionalHeaders: [String: String] {
        ["Content-Type": "application/json"]
    }

    /// Encodes the data to be included in the body of the request.
    ///
    /// - Returns: The encoded data to include in the body of the request.
    ///
    func encode() throws -> Data {
        try Self.encoder.encode(self)
    }
}

/// Conforms `Data` to `RequestBody`.
///
extension Data: RequestBody {
    public var additionalHeaders: [String: String] { [:] }
    public func encode() throws -> Data { self }
}
