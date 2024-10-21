import XCTest

@testable import BitwardenShared

class DefaultFalseTests: BitwardenTestCase {
    // MARK: Types

    struct Model: Codable, Equatable {
        @DefaultFalse var value: Bool
    }

    // MARK: Tests

    /// `DefaultFalse` encodes a `false` wrapped value.
    func test_encode_false() throws {
        let subject = Model(value: false)
        let data = try JSONEncoder().encode(subject)
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"value":false}"#)
    }

    /// `DefaultFalse` encodes a `true` wrapped value.
    func test_encode_true() throws {
        let subject = Model(value: true)
        let data = try JSONEncoder().encode(subject)
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"value":true}"#)
    }

    /// Decoding a `DefaultFalse` wrapped value will decode a `false` value from the JSON.
    func test_decode_false() throws {
        let json = #"{"value": true}"#
        let data = try XCTUnwrap(json.data(using: .utf8))
        let subject = try JSONDecoder().decode(Model.self, from: data)
        XCTAssertEqual(subject, Model(value: true))
    }

    /// Decoding a `DefaultFalse` wrapped value will default the value to `false` if the key is
    /// missing from the JSON.
    func test_decode_missing() throws {
        let json = #"{}"#
        let data = try XCTUnwrap(json.data(using: .utf8))
        let subject = try JSONDecoder().decode(Model.self, from: data)
        XCTAssertEqual(subject, Model(value: false))
    }

    /// Decoding a `DefaultFalse` wrapped value will default the value to `false` if the value is
    /// `null` in the JSON.
    func test_decode_null() throws {
        let json = #"{"value": null}"#
        let data = try XCTUnwrap(json.data(using: .utf8))
        let subject = try JSONDecoder().decode(Model.self, from: data)
        XCTAssertEqual(subject, Model(value: false))
    }

    /// Decoding a `DefaultFalse` wrapped value will decode a `true` value from the JSON.
    func test_decode_true() throws {
        let json = #"{"value": true}"#
        let data = try XCTUnwrap(json.data(using: .utf8))
        let subject = try JSONDecoder().decode(Model.self, from: data)
        XCTAssertEqual(subject, Model(value: true))
    }
}
