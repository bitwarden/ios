import OSLog

// MARK: - DefaultValueProvider

/// A protocol for defining a default value for a `Decodable` type if an invalid or missing value
/// is received.
///
public protocol DefaultValueProvider: Decodable {
    /// The default value to use if the value to decode is invalid or missing.
    static var defaultValue: Self { get }
}

// MARK: - DefaultValue

/// A property wrapper that will default the wrapped value to a default value if decoding fails.
/// This is useful for decoding types which may not be present in the response or to prevent a
/// decoding failure if an invalid value is received.
///
/// The decoded value is stored as an `OpenEnum`, which is available as the projected value
/// (`$property`). This preserves an unrecognized raw value so that it can be logged, and so that
/// encoding writes back the original raw value instead of the default. A persisted model then
/// round-trips and resolves to the known value once the app learns the new case.
///
/// ```swift
/// struct DeviceResponse: Codable {
///     @DefaultValue var type: DeviceType
/// }
///
/// response.type  // .unknownBrowser when the server sent 99
/// response.$type // .unknown(99); nil if missing, null, or the wrong JSON type
/// ```
///
@propertyWrapper
public struct DefaultValue<T: DefaultValueProvider & RawRepresentable> where T.RawValue: Codable {
    // MARK: Properties

    /// The decoded value, or `nil` if the value was missing, `null`, or the wrong JSON type.
    public var projectedValue: OpenEnum<T>?

    /// The known value, falling back to `T.defaultValue` if the value is unrecognized, missing,
    /// `null`, or the wrong JSON type.
    public var wrappedValue: T {
        projectedValue?.knownValue ?? T.defaultValue
    }

    /// The raw value that's encoded: the original raw value if there is one, otherwise the default
    /// value's raw value.
    var encodedRawValue: T.RawValue {
        projectedValue?.rawValue ?? T.defaultValue.rawValue
    }

    // MARK: Initialization

    /// Creates a new `DefaultValue` with the specified wrapped value.
    ///
    /// - Parameter wrappedValue: The value to wrap.
    ///
    public init(wrappedValue: T) {
        projectedValue = .known(wrappedValue)
    }

    /// Creates a new `DefaultValue` with the specified underlying value, which may be unrecognized.
    ///
    /// - Parameter value: The underlying `OpenEnum` value, or `nil` to use the default value.
    ///
    public init(_ value: OpenEnum<T>?) {
        projectedValue = value
    }
}

// MARK: - Decodable

extension DefaultValue: Decodable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil(), let rawValue = try? container.decode(T.RawValue.self) {
            let value = OpenEnum<T>(rawValue: rawValue)
            if case .unknown = value {
                Self.logInvalidValue(in: container)
            }
            projectedValue = value
        } else {
            // Falls back to the default for `null` or a raw value of the wrong JSON type.
            Self.logInvalidValue(in: container)
            projectedValue = nil
        }
    }

    /// Logs a warning for a value that can't be initialized to `T`.
    ///
    /// - Parameter container: The container holding the invalid value.
    ///
    private static func logInvalidValue(in container: any SingleValueDecodingContainer) {
        if let intValue = try? container.decode(Int.self) {
            Logger.application.warning(
                """
                Cannot initialize \(T.self) from invalid Int value \(intValue, privacy: .private), \
                defaulting to \(String(describing: T.defaultValue)).
                """,
            )
        } else if let stringValue = try? container.decode(String.self) {
            Logger.application.warning(
                """
                Cannot initialize \(T.self) from invalid String value \(stringValue, privacy: .private), \
                defaulting to \(String(describing: T.defaultValue))
                """,
            )
        } else {
            Logger.application.warning(
                """
                Cannot initialize \(T.self) from invalid unknown valid, \
                defaulting to \(String(describing: T.defaultValue))
                """,
            )
        }
    }
}

// MARK: - Encodable

extension DefaultValue: Encodable {
    public func encode(to encoder: any Encoder) throws {
        // Encodes the original raw value if there is one, so that an unrecognized value isn't
        // replaced by the default when persisted. Otherwise, encodes the default value.
        var container = encoder.singleValueContainer()
        try container.encode(encodedRawValue)
    }
}

// MARK: - Equatable

extension DefaultValue: Equatable where T: Equatable, T.RawValue: Equatable {
    /// Two values are equal if they encode to the same raw value. A missing, `null`, or invalid
    /// value is equal to the default value, while an unrecognized raw value is only equal to the
    /// same unrecognized raw value.
    public static func == (lhs: DefaultValue, rhs: DefaultValue) -> Bool {
        lhs.encodedRawValue == rhs.encodedRawValue
    }
}

// MARK: - Hashable

extension DefaultValue: Hashable where T: Hashable, T.RawValue: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(encodedRawValue)
    }
}

// MARK: - Sendable

extension DefaultValue: Sendable where T: Sendable, T.RawValue: Sendable {}

// MARK: - KeyedDecodingContainer

public extension KeyedDecodingContainer {
    /// When decoding a `DefaultValue` wrapped value, if the property doesn't exist, default to the
    /// type's default value.
    ///
    /// - Parameters:
    ///   - type: The type of value to attempt to decode.
    ///   - key: The key used to decode the value.
    ///
    func decode<T>(_ type: DefaultValue<T>.Type, forKey key: Key) throws -> DefaultValue<T> {
        if let value = try decodeIfPresent(DefaultValue<T>.self, forKey: key) {
            return value
        } else {
            Logger.application.warning(
                "Missing value for \(T.self), defaulting to \(String(describing: T.defaultValue))",
            )
            return DefaultValue(nil)
        }
    }
}
