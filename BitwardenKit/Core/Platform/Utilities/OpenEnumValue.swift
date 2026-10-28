// MARK: - OpenEnumValue

/// A property wrapper over `OpenEnum` for an enum that has no sensible fallback value, where an
/// unrecognized value means the item should be dropped or an error thrown.
///
/// The wrapped value is the known enum value, or `nil` if the raw value isn't recognized, or the
/// value is missing or `null`. The projected value (`$property`) is the underlying `OpenEnum`,
/// which preserves the original raw value for logging and encoding.
///
/// Unlike a bare `OpenEnum` property, the memberwise initializer takes the plain enum value, so
/// fixtures and tests don't need to wrap known values in `.known(...)`.
///
/// ```swift
/// struct PolicyResponseModel: Codable {
///     @OpenEnumValue var type: PolicyType?
/// }
///
/// response.type            // PolicyType?
/// response.$type?.rawValue // 23
/// ```
///
@propertyWrapper
public struct OpenEnumValue<Known: RawRepresentable> where Known.RawValue: Codable {
    // MARK: Properties

    /// The underlying value, which preserves unrecognized raw values. This is `nil` if the value
    /// was missing or `null`.
    public var projectedValue: OpenEnum<Known>?

    /// The known enum value, or `nil` if the value is unrecognized, missing, or `null`.
    public var wrappedValue: Known? {
        projectedValue?.knownValue
    }

    // MARK: Initialization

    /// Initialize an `OpenEnumValue` with a known enum value.
    ///
    /// - Parameter wrappedValue: The known enum value, or `nil` for no value.
    ///
    public init(wrappedValue: Known?) {
        projectedValue = wrappedValue.map(OpenEnum.known)
    }

    /// Initialize an `OpenEnumValue` with an `OpenEnum`, which may be unrecognized.
    ///
    /// - Parameter value: The underlying `OpenEnum` value, or `nil` for no value.
    ///
    public init(_ value: OpenEnum<Known>?) {
        projectedValue = value
    }
}

// MARK: - Decodable

extension OpenEnumValue: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        projectedValue = container.decodeNil() ? nil : try container.decode(OpenEnum<Known>.self)
    }
}

// MARK: - Encodable

extension OpenEnumValue: Encodable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(projectedValue)
    }
}

// MARK: - Equatable

extension OpenEnumValue: Equatable where Known: Equatable, Known.RawValue: Equatable {}

// MARK: - Hashable

extension OpenEnumValue: Hashable where Known: Hashable, Known.RawValue: Hashable {}

// MARK: - Sendable

extension OpenEnumValue: Sendable where Known: Sendable, Known.RawValue: Sendable {}

// MARK: - KeyedDecodingContainer

public extension KeyedDecodingContainer {
    /// When decoding an `OpenEnumValue` wrapped value, treat a missing key as `nil` rather than
    /// throwing, matching a plain optional property.
    ///
    /// - Parameters:
    ///   - type: The type of value to attempt to decode.
    ///   - key: The key used to decode the value.
    ///
    func decode<T>(_ type: OpenEnumValue<T>.Type, forKey key: Key) throws -> OpenEnumValue<T> {
        try decodeIfPresent(type, forKey: key) ?? OpenEnumValue(nil)
    }
}

// MARK: - KeyedEncodingContainer

public extension KeyedEncodingContainer {
    /// When encoding an `OpenEnumValue` wrapped value, omit the key if the value is `nil`, matching
    /// a plain optional property.
    ///
    /// - Parameters:
    ///   - value: The value to encode.
    ///   - key: The key to associate the value with.
    ///
    mutating func encode<T>(_ value: OpenEnumValue<T>, forKey key: Key) throws {
        try encodeIfPresent(value.projectedValue, forKey: key)
    }
}
