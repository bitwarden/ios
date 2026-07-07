import Foundation

// MARK: - CompactDecodable

/// A property wrapper that decodes a `[String: T?]` dictionary and drops any null-valued entries,
/// producing a `[String: T]?`. When the value is absent or null the `wrappedValue` is `nil`.
///
/// Usage:
/// ```swift
/// @CompactDecodable var pathnames: [String: FormsMapPathnameEntry]?
/// ```
@propertyWrapper
struct CompactDecodable<T: Decodable>: Decodable {
    var wrappedValue: [String: T]?

    init(wrappedValue: [String: T]? = nil) {
        self.wrappedValue = wrappedValue
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = nil
        } else {
            let nullable = try container.decode([String: T?].self)
            wrappedValue = nullable.compactMapValues { $0 }
        }
    }
}

extension CompactDecodable: Equatable where T: Equatable {}
extension CompactDecodable: Encodable where T: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

// MARK: - KeyedDecodingContainer

extension KeyedDecodingContainer {
    /// Intercepts the synthesised `decode(_:forKey:)` call emitted for `@CompactDecodable`
    /// properties and routes it through `decodeIfPresent`, so a missing key returns the
    /// default `CompactDecodable()` (i.e. `wrappedValue: nil`) instead of throwing.
    func decode<T: Decodable>(
        _ type: CompactDecodable<T>.Type,
        forKey key: Key,
    ) throws -> CompactDecodable<T> {
        try decodeIfPresent(type, forKey: key) ?? CompactDecodable()
    }
}
