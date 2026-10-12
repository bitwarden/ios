// MARK: - AnyCodable

/// A custom codable type that can be used to encode/decode a variety of primitive types.
///
public enum AnyCodable: Codable, Equatable, Sendable {
    /// The wrapped value is an array of `AnyCodable` values.
    case array([AnyCodable])

    /// The wrapped value is a bool value.
    case bool(Bool)

    /// The wrapped value is a keyed dictionary of `AnyCodable` values.
    case dictionary([String: AnyCodable])

    /// The wrapped value is a double value.
    case double(Double)

    /// The wrapped value is an int value.
    case int(Int)

    /// The wrapped value is a null value.
    case null

    /// The wrapped value is a string value.
    case string(String)

    // MARK: Decodable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            // Double needs to attempt decoding after `Int` otherwise it will capture any integer values.
            self = .double(doubleValue)
        } else if container.decodeNil() {
            self = .null
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            self = .array(arrayValue)
        } else if let dictionaryValue = try? container.decode([String: AnyCodable].self) {
            self = .dictionary(dictionaryValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode AnyCodable value.",
            )
        }
    }

    // MARK: Encodable

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .array(arrayValue):
            try container.encode(arrayValue)
        case let .bool(boolValue):
            try container.encode(boolValue)
        case let .dictionary(dictionaryValue):
            try container.encode(dictionaryValue)
        case let .double(doubleValue):
            try container.encode(doubleValue)
        case let .int(intValue):
            try container.encode(intValue)
        case .null:
            try container.encodeNil()
        case let .string(stringValue):
            try container.encode(stringValue)
        }
    }
}

public extension AnyCodable {
    /// Returns the associated array value if the type is `array`.
    var arrayValue: [AnyCodable]? {
        guard case let .array(arrayValue) = self else { return nil }
        return arrayValue
    }

    /// Returns the associated bool value if the type is `bool`.
    var boolValue: Bool? {
        guard case let .bool(boolValue) = self else { return nil }
        return boolValue
    }

    /// Returns the associated dictionary value if the type is `dictionary`.
    var dictionaryValue: [String: AnyCodable]? {
        guard case let .dictionary(dictionaryValue) = self else { return nil }
        return dictionaryValue
    }

    /// Returns the associated double value if the type is `double` or could be converted to `Double`.
    var doubleValue: Double? {
        switch self {
        case .array, .dictionary:
            nil
        case let .bool(boolValue):
            boolValue ? 1 : 0
        case let .double(doubleValue):
            doubleValue
        case let .int(intValue):
            Double(intValue)
        case .null:
            nil
        case let .string(stringValue):
            Double(stringValue)
        }
    }

    /// Returns the associated int value if the type is `int` or could be converted to `Int`.
    var intValue: Int? {
        switch self {
        case .array, .dictionary:
            nil
        case let .bool(boolValue):
            boolValue ? 1 : 0
        case let .double(doubleValue):
            Int(doubleValue)
        case let .int(intValue):
            intValue
        case .null:
            nil
        case let .string(stringValue):
            Int(stringValue)
        }
    }

    /// Returns the associated string value if the type is `string`.
    var stringValue: String? {
        guard case let .string(stringValue) = self else { return nil }
        return stringValue
    }
}
