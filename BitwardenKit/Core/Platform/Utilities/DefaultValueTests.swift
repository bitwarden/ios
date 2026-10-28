import XCTest

@testable import BitwardenKit

class DefaultValueTests: BitwardenTestCase {
    // MARK: Types

    enum ValueType: String, Codable, DefaultValueProvider {
        case one, two, three

        static var defaultValue: ValueType { .one }
    }

    /// An `Int` raw-value enum, like the server enums that use `DefaultValue`.
    enum IntValueType: Int, Codable, DefaultValueProvider {
        case unknown = -1
        case one = 1

        static var defaultValue: IntValueType { .unknown }
    }

    /// `IntValueType` after a later version of the app adds a new case.
    enum UpdatedIntValueType: Int, Codable, DefaultValueProvider {
        case unknown = -1
        case one = 1
        case two = 2

        static var defaultValue: UpdatedIntValueType { .unknown }
    }

    struct Model: Codable, Equatable {
        @DefaultValue var value: ValueType
    }

    struct IntModel: Codable, Hashable {
        @DefaultValue var value: IntValueType
    }

    struct UpdatedIntModel: Codable, Equatable {
        @DefaultValue var value: UpdatedIntValueType
    }

    // MARK: Tests

    /// `DefaultValue` encodes the wrapped value.
    func test_encode() throws {
        let subject = Model(value: .two)
        XCTAssertEqual(try encode(subject), #"{"value":"two"}"#)
    }

    /// `DefaultValue` encodes the default value if the value was missing.
    func test_encode_missing() throws {
        let subject = try decode(Model.self, #"{}"#)
        XCTAssertEqual(try encode(subject), #"{"value":"one"}"#)
    }

    /// `DefaultValue` encodes the original raw value of an unrecognized value, rather than the
    /// default value.
    func test_encode_unknownValue_roundTrips() throws {
        let json = #"{"value":2}"#
        let subject = try decode(IntModel.self, json)
        XCTAssertEqual(try encode(subject), json)
    }

    /// A persisted unrecognized value decodes to the known value once the enum gains the case.
    func test_encode_persistedUnknownValue_resolvesWhenCaseIsAdded() throws {
        let persisted = try encode(decode(IntModel.self, #"{"value": 2}"#))
        let subject = try decode(UpdatedIntModel.self, persisted)
        XCTAssertEqual(subject.value, .two)
        XCTAssertEqual(subject.$value, .known(.two))
    }

    /// Decoding a `DefaultValue` wrapped value will use the default value if an array cannot be
    /// initialized to the type.
    func test_decode_invalidArray() throws {
        let subject = try decode(Model.self, #"{"value": ["three"]}"#)
        XCTAssertEqual(subject, Model(value: .one))
        XCTAssertNil(subject.$value)
    }

    /// Decoding a `DefaultValue` wrapped value will use the default value if an int value cannot
    /// be initialized to the type.
    func test_decode_invalidInt() throws {
        let subject = try decode(Model.self, #"{"value": 5}"#)
        XCTAssertEqual(subject, Model(value: .one))
        XCTAssertNil(subject.$value)
    }

    /// Decoding a `DefaultValue` wrapped value will use the default value if a string value cannot
    /// be initialized to the type, preserving the unrecognized raw value.
    func test_decode_invalidString() throws {
        let subject = try decode(Model.self, #"{"value": "unknown"}"#)
        XCTAssertEqual(subject.value, .one)
        XCTAssertEqual(subject.$value, .unknown("unknown"))
    }

    /// Decoding a `DefaultValue` wrapped value will use the default value if the value is
    /// unknown in the JSON.
    func test_decode_missing() throws {
        let subject = try decode(Model.self, #"{}"#)
        XCTAssertEqual(subject, Model(value: .one))
        XCTAssertNil(subject.$value)
    }

    /// Decoding a `DefaultValue` wrapped value will use the default value if the value is `null`
    /// in the JSON.
    func test_decode_null() throws {
        let subject = try decode(Model.self, #"{"value": null}"#)
        XCTAssertEqual(subject, Model(value: .one))
        XCTAssertNil(subject.$value)
    }

    /// Decoding a `DefaultValue` wrapped value will use the default value if an `Int` raw value
    /// isn't recognized, preserving the unrecognized raw value.
    func test_decode_unknownIntValue() throws {
        let subject = try decode(IntModel.self, #"{"value": 2}"#)
        XCTAssertEqual(subject.value, .unknown)
        XCTAssertEqual(subject.$value, .unknown(2))
    }

    /// Decoding a `DefaultValue` wrapped value will decode the enum value from the JSON.
    func test_decode_value() throws {
        let subject = try decode(Model.self, #"{"value": "three"}"#)
        XCTAssertEqual(subject, Model(value: .three))
        XCTAssertEqual(subject.$value, .known(.three))
    }

    /// `DefaultValue` values are equal if they encode to the same raw value: a missing value
    /// equals the default value, but an unrecognized value doesn't.
    func test_equatableAndHashable() throws {
        let missing = try decode(IntModel.self, #"{}"#)
        let explicitDefault = IntModel(value: .unknown)
        let unrecognized = try decode(IntModel.self, #"{"value": 2}"#)

        XCTAssertEqual(missing, explicitDefault)
        XCTAssertEqual(missing.hashValue, explicitDefault.hashValue)
        XCTAssertNotEqual(unrecognized, explicitDefault)
        XCTAssertEqual(unrecognized, try decode(IntModel.self, #"{"value": 2}"#))
    }

    /// `init(wrappedValue:)` stores the value as a known value.
    func test_init_wrappedValue() {
        let subject = Model(value: .two)
        XCTAssertEqual(subject.value, .two)
        XCTAssertEqual(subject.$value, .known(.two))
    }

    /// The projected value can be set to an unrecognized value.
    func test_projectedValue_set() throws {
        var subject = IntModel(value: .one)
        subject.$value = .unknown(2)
        XCTAssertEqual(subject.value, .unknown)
        XCTAssertEqual(try encode(subject), #"{"value":2}"#)
    }

    // MARK: Private

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    private func encode(_ value: some Encodable) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(value)
        return try XCTUnwrap(String(bytes: data, encoding: .utf8))
    }
}
