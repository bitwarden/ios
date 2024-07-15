import Foundation
import Networking

extension JSONRequestBody {
    /// The encoder used by default to encode JSON request bodies for the API.
    public static var encoder: JSONEncoder { .defaultEncoder }
}

// MARK: - Array + RequestBody

/// Conforms `Array` to `RequestBody`.
extension Array: RequestBody, JSONRequestBody where Element: Codable {
    public var additionalHeaders: [String: String] {
        ["Content-Type": "application/json"]
    }

    public func encode() throws -> Data {
        try Self.encoder.encode(self)
    }
}
