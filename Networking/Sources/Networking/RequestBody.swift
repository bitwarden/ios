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

// MARK: - JSONRequestBody

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

// MARK: - Data + RequestBody

/// Conforms `Data` to `RequestBody`.
///
extension Data: RequestBody {
    public var additionalHeaders: [String: String] { [:] }
    public func encode() throws -> Data { self }
}

// MARK: - FormURLEncodedRequestBody

/// A protocol for a `RequestBody` that can be encoded as an URL encoded form for the body of a
/// request.
///
public protocol FormURLEncodedRequestBody: RequestBody {
    /// A list of `URLQueryItem`s to encode in the body.
    var values: [URLQueryItem] { get }
}

public extension FormURLEncodedRequestBody {
    /// Additional headers to append to the request headers.
    var additionalHeaders: [String: String] {
        ["Content-Type": "application/x-www-form-urlencoded"]
    }

    /// Encodes the data to be included in the body of the request.
    ///
    /// - Returns: The encoded data to include in the body of the request.
    ///
    func encode() throws -> Data {
        let bodyString = values
            .map { percentEncode($0.name) + "=" + percentEncode($0.value ?? "") }
            .joined(separator: "&")
        return Data(bodyString.utf8)
    }

    // MARK: Private

    /// Percent encodes the specified string.
    ///
    /// - Parameter string: The string to apply percent encoding to.
    /// - Returns: The percent encoded string.
    ///
    private func percentEncode(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
    }
}
