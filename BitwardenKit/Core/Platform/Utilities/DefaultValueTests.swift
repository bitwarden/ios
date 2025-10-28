import XCTest

@testable import BitwardenKit

class DefaultValueTests: BitwardenTestCase {
    // MARK: Types

    enum ValueType: String, Codable, DefaultValueProvider {
        case one, two, three

        static var defaultValue: ValueType { .one }
    }

    struct Model: Codable, Equatable {
        @DefaultValue var value: ValueType
    }

    // MARK: Tests

    /// `DefaultValue` encodes the wrapped value.
    func test_encode() throws {
        let subject = Model(value: .two)
        let data = try JSONEncoder().encode(subject)
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"value":"two"}"#)
    }

    /// Decoding a `DefaultValue` wrapped value will use the default value if an array cannot be
    /// initialized to the type.
    func test_decode_invalidArray() throws {
        let json = #"{"value": ["three"]}"#
        let data = try XCTUnwrap(json.data(using: .utf8))
        let subject = try JSONDecoder().decode(Model.self, from: data)
        XCTAssertEqual(subject, Model(value: .one))
    }

    /// Decoding a `DefaultValue` wrapped value will use the default value if an int value cannot
    /// be initialized to the type.
    func test_decode_invalidInt() throws {
        let json = #"{"value": 5}"#
        let data = try XCTUnwrap(json.data(using: .utf8))
        let subject = try JSONDecoder().decode(Model.self, from: data)
        XCTAssertEqual(subject, Model(value: .one))
    }

    /// Decoding a `DefaultValue` wrapped value will use the default value if a string value cannot
    /// be initialized to the type.
    func test_decode_invalidString() throws {
        let json = #"{"value": "unknown"}"#
        let data = try XCTUnwrap(json.data(using: .utf8))
        let subject = try JSONDecoder().decode(Model.self, from: data)
        XCTAssertEqual(subject, Model(value: .one))
    }

    /// Decoding a `DefaultValue` wrapped value will use the default value if the value is
    /// unknown in the JSON.
    func test_decode_missing() throws {
        let json = #"{}"#
        let data = try XCTUnwrap(json.data(using: .utf8))
        let subject = try JSONDecoder().decode(Model.self, from: data)
        XCTAssertEqual(subject, Model(value: .one))
    }

    /// Decoding a `DefaultValue` wrapped value will use the default value if the value is `null`
    /// in the JSON.
    func test_decode_null() throws {
        let json = #"{"value": null}"#
        let data = try XCTUnwrap(json.data(using: .utf8))
        let subject = try JSONDecoder().decode(Model.self, from: data)
        XCTAssertEqual(subject, Model(value: .one))
    }

    /// Decoding a `DefaultValue` wrapped value will decode the enum value from the JSON.
    func test_decode_value() throws {
        let json = #"{"value": "three"}"#
        let data = try XCTUnwrap(json.data(using: .utf8))
        let subject = try JSONDecoder().decode(Model.self, from: data)
        XCTAssertEqual(subject, Model(value: .three))
    }
}
