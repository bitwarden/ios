// MARK: - AnyCodable

/// A custom codable type that can be used to encode/decode a variety of primitive types.
///
enum AnyCodable: Codable, Equatable {
    /// The wrapped value is a bool value.
    case bool(Bool)

    /// The wrapped value is an int value.
    case int(Int)

    /// The wrapped value is a null value.
    case null

    /// The wrapped value is a string value.
    case string(String)

    // MARK: Decodable

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let boolValue = try? container.decode(Bool.self) {
            self = .bool(boolValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if container.decodeNil() {
            self = .null
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unable to decode AnyCodable value."
            )
        }
    }

    // MARK: Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case let .bool(boolValue):
            try container.encode(boolValue)
        case let .int(intValue):
            try container.encode(intValue)
        case .null:
            try container.encodeNil()
        case let .string(stringValue):
            try container.encode(stringValue)
        }
    }
}

extension AnyCodable {
    /// Returns the associated bool value if the type is `bool`.
    var boolValue: Bool? {
        guard case let .bool(boolValue) = self else { return nil }
        return boolValue
    }

    /// Returns the associated int value if the type is `int`.
    var intValue: Int? {
        guard case let .int(intValue) = self else { return nil }
        return intValue
    }

    /// Returns the associated string value if the type is `string`.
    var stringValue: String? {
        guard case let .string(stringValue) = self else { return nil }
        return stringValue
    }
}
