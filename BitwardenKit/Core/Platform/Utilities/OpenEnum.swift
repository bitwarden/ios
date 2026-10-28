import OSLog

// MARK: - OpenEnum

/// A wrapper for a `RawRepresentable` enum decoded from an API response that tolerates raw values
/// the client doesn't recognize yet.
///
/// Swift's synthesized `Decodable` conformance for raw-value enums is a closed contract: an
/// unrecognized raw value throws and fails decoding of the entire response. `OpenEnum` instead
/// decodes unrecognized values as `.unknown(rawValue)`, preserving the original raw value so it
/// can be logged, persisted, and re-encoded without loss.
///
/// The wrapped enum stays exhaustive and doesn't need an `unknown` case or a custom decoder, and
/// it only needs to be `RawRepresentable`, so SDK enums (which aren't `Codable`) can be wrapped too.
///
/// ```swift
/// struct PolicyResponseModel: Codable {
///     let type: OpenEnum<PolicyType>
/// }
/// ```
///
public enum OpenEnum<Known: RawRepresentable> where Known.RawValue: Codable {
    /// A raw value that maps to a case of the known enum.
    case known(Known)

    /// A raw value that the client doesn't recognize.
    case unknown(Known.RawValue)

    // MARK: Properties

    /// The known enum value, or `nil` if the raw value isn't recognized.
    public var knownValue: Known? {
        guard case let .known(value) = self else { return nil }
        return value
    }

    /// The original raw value.
    public var rawValue: Known.RawValue {
        switch self {
        case let .known(value): value.rawValue
        case let .unknown(rawValue): rawValue
        }
    }

    // MARK: Initialization

    /// Initialize an `OpenEnum` from a known enum value.
    ///
    /// - Parameter value: The known enum value.
    ///
    public init(_ value: Known) {
        self = .known(value)
    }

    /// Initialize an `OpenEnum` from a raw value, which may or may not map to a known value.
    ///
    /// - Parameter rawValue: The raw value.
    ///
    public init(rawValue: Known.RawValue) {
        if let value = Known(rawValue: rawValue) {
            self = .known(value)
        } else {
            self = .unknown(rawValue)
        }
    }
}

// MARK: - Decodable

extension OpenEnum: Decodable {
    public init(from decoder: any Decoder) throws {
        // Note: a raw value of the wrong JSON type (e.g. a string for an `Int` enum) still throws.
        // That's a contract violation rather than a server-side enum addition.
        let rawValue = try decoder.singleValueContainer().decode(Known.RawValue.self)
        self.init(rawValue: rawValue)
        if case .unknown = self {
            Logger.application.warning(
                "Decoded unknown \(Known.self) raw value \(String(describing: rawValue), privacy: .private)",
            )
        }
    }
}

// MARK: - Encodable

extension OpenEnum: Encodable {
    public func encode(to encoder: any Encoder) throws {
        // Encodes the original raw value so that persisted models round-trip without loss.
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

// MARK: - Equatable

extension OpenEnum: Equatable where Known: Equatable, Known.RawValue: Equatable {
    /// Compares an `OpenEnum` to a known value, e.g. `policy.type == .disableSend`.
    ///
    /// - Parameters:
    ///   - lhs: The `OpenEnum` value.
    ///   - rhs: The known value to compare against.
    /// - Returns: `true` if `lhs` is `.known` and its value equals `rhs`.
    ///
    public static func == (lhs: OpenEnum, rhs: Known) -> Bool {
        lhs.knownValue == rhs
    }

    /// Compares an `OpenEnum` to a known value, e.g. `policy.type != .disableSend`.
    ///
    /// - Parameters:
    ///   - lhs: The `OpenEnum` value.
    ///   - rhs: The known value to compare against.
    /// - Returns: `true` if `lhs` is `.unknown` or its value doesn't equal `rhs`.
    ///
    public static func != (lhs: OpenEnum, rhs: Known) -> Bool {
        !(lhs == rhs)
    }
}

// MARK: - Hashable

extension OpenEnum: Hashable where Known: Hashable, Known.RawValue: Hashable {}

// MARK: - Sendable

extension OpenEnum: Sendable where Known: Sendable, Known.RawValue: Sendable {}

// MARK: - CustomStringConvertible

extension OpenEnum: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .known(value): "\(value)"
        case let .unknown(rawValue): "unknown(\(rawValue))"
        }
    }
}
