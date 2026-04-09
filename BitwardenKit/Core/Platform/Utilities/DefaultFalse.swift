/// A property wrapper that will default the wrapped value to `false` if decoding fails. This is
/// useful for decoding a boolean value which may not be present in the response.
///
@propertyWrapper
public struct DefaultFalse: Codable, Hashable {
    // MARK: Properties

    /// The wrapped value.
    public var wrappedValue: Bool

    // MARK: Initialization

    /// Initialize a `DefaultFalse` with a wrapped value.
    ///
    /// - Parameter wrappedValue: The value that is contained in the property wrapper.
    ///
    public init(wrappedValue: Bool) {
        self.wrappedValue = wrappedValue
    }

    // MARK: Decodable

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(Bool.self)
    }

    // MARK: Encodable

    public func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

// MARK: - KeyedDecodingContainer

public extension KeyedDecodingContainer {
    /// When decoding a `DefaultFalse` wrapped value, if the property doesn't exist, default to `false`.
    ///
    /// - Parameters:
    ///   - type: The type of value to attempt to decode.
    ///   - key: The key used to decode the value.
    ///
    func decode(_ type: DefaultFalse.Type, forKey key: Key) throws -> DefaultFalse {
        try decodeIfPresent(type, forKey: key) ?? DefaultFalse(wrappedValue: false)
    }
}
