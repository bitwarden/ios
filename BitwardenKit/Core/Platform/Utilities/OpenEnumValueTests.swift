import Foundation
import Testing

@testable import BitwardenKit

struct OpenEnumValueTests {
    // MARK: Types

    /// An `Int` raw-value enum, like most server enums.
    enum Fruit: Int, Codable {
        case apple = 1
        case banana = 2
    }

    struct Model: Codable, Equatable {
        let id: String
        @OpenEnumValue var fruit: Fruit?
    }

    // MARK: Tests

    /// `init(from:)` decodes a known raw value.
    @Test
    func decode_knownValue() throws {
        let subject = try decode(#"{"id": "1", "fruit": 2}"#)
        #expect(subject.fruit == .banana)
        #expect(subject.$fruit == .known(.banana))
    }

    /// `init(from:)` decodes a missing key as `nil`.
    @Test
    func decode_missing() throws {
        let subject = try decode(#"{"id": "1"}"#)
        #expect(subject.fruit == nil)
        #expect(subject.$fruit == nil)
    }

    /// `init(from:)` decodes a `null` value as `nil`.
    @Test
    func decode_null() throws {
        let subject = try decode(#"{"id": "1", "fruit": null}"#)
        #expect(subject.fruit == nil)
        #expect(subject.$fruit == nil)
    }

    /// `init(from:)` decodes an unrecognized raw value as a `nil` wrapped value, preserving the raw
    /// value in the projected value.
    @Test
    func decode_unknownValue_preservesRawValue() throws {
        let subject = try decode(#"{"id": "1", "fruit": 23}"#)
        #expect(subject.fruit == nil)
        #expect(subject.$fruit == .unknown(23))
        #expect(subject.$fruit?.rawValue == 23)
    }

    /// `init(from:)` throws if the raw value is the wrong JSON type, like `OpenEnum`.
    @Test
    func decode_wrongJSONType_throws() {
        #expect(throws: DecodingError.self) {
            try decode(#"{"id": "1", "fruit": "apple"}"#)
        }
    }

    /// `encode(to:)` encodes a known value's raw value.
    @Test
    func encode_knownValue() throws {
        #expect(try encode(Model(id: "1", fruit: .apple)) == #"{"fruit":1,"id":"1"}"#)
    }

    /// `encode(to:)` omits the key for a `nil` value.
    @Test
    func encode_nil_omitsKey() throws {
        #expect(try encode(Model(id: "1", fruit: nil)) == #"{"id":"1"}"#)
    }

    /// `encode(to:)` round-trips an unknown raw value without loss.
    @Test
    func encode_unknownValue_roundTrips() throws {
        let json = #"{"fruit":23,"id":"1"}"#
        #expect(try encode(decode(json)) == json)
    }

    /// The memberwise initializer takes the plain enum value.
    @Test
    func init_memberwise() {
        let subject = Model(id: "1", fruit: .apple)
        #expect(subject.fruit == .apple)
        #expect(subject.$fruit == .known(.apple))
    }

    /// The projected value can be set to an unrecognized value.
    @Test
    func projectedValue_set() throws {
        var subject = Model(id: "1", fruit: .apple)
        subject.$fruit = .unknown(23)
        #expect(subject.fruit == nil)
        #expect(subject != Model(id: "1", fruit: nil))
        #expect(try encode(subject) == #"{"fruit":23,"id":"1"}"#)
    }

    // MARK: Private

    private func decode(_ json: String) throws -> Model {
        try JSONDecoder().decode(Model.self, from: Data(json.utf8))
    }

    private func encode(_ value: some Encodable) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(value)
        return try #require(String(bytes: data, encoding: .utf8))
    }
}
