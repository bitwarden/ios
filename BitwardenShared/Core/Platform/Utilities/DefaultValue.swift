import OSLog

// MARK: - DefaultValueProvider

/// A protocol for defining a default value for a `Decodable` type if an invalid or missing value
/// is received.
///
protocol DefaultValueProvider: Decodable {
    /// The default value to use if the value to decode is invalid or missing.
    static var defaultValue: Self { get }
}

// MARK: - DefaultValue

/// A property wrapper that will default the wrapped value to a default value if decoding fails.
/// This is useful for decoding types which may not be present in the response or to prevent a
/// decoding failure if an invalid value is received.
///
@propertyWrapper
struct DefaultValue<T: DefaultValueProvider> {
    // MARK: Properties

    /// The wrapped value.
    let wrappedValue: T
}

// MARK: - Decodable

extension DefaultValue: Decodable {
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            wrappedValue = try container.decode(T.self)
        } catch {
            if let intValue = try? container.decode(Int.self) {
                Logger.application.warning(
                    """
                    Cannot initialize \(T.self) from invalid Int value \(intValue), \
                    defaulting to \(String(describing: T.defaultValue)).
                    """
                )
            } else if let stringValue = try? container.decode(String.self) {
                Logger.application.warning(
                    """
                    Cannot initialize \(T.self) from invalid String value \(stringValue), \
                    defaulting to \(String(describing: T.defaultValue))
                    """
                )
            } else {
                Logger.application.warning(
                    """
                    Cannot initialize \(T.self) from invalid unknown valid, \
                    defaulting to \(String(describing: T.defaultValue))
                    """
                )
            }
            wrappedValue = T.defaultValue
        }
    }
}

// MARK: - Encodable

extension DefaultValue: Encodable where T: Encodable {
    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
}

// MARK: - Equatable

extension DefaultValue: Equatable where T: Equatable {}

// MARK: - Hashable

extension DefaultValue: Hashable where T: Hashable {}

// MARK: - KeyedDecodingContainer

extension KeyedDecodingContainer {
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
                "Missing value for \(T.self), defaulting to \(String(describing: T.defaultValue))"
            )
            return DefaultValue(wrappedValue: T.defaultValue)
        }
    }
}
