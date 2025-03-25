import Foundation
import Networking

public extension JSONRequestBody {
    /// The encoder used by default to encode JSON request bodies for the API.
    static var encoder: JSONEncoder { .defaultEncoder }
}

// MARK: - Array + RequestBody

/// Conforms `Array` to `RequestBody`.
extension Array: @retroactive RequestBody, @retroactive JSONRequestBody where Element: Codable {
    public var additionalHeaders: [String: String] {
        ["Content-Type": "application/json"]
    }

    public func encode() throws -> Data {
        try Self.encoder.encode(self)
    }
}
