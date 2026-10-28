import Foundation
import Testing

@testable import BitwardenKit

struct OpenEnumTests {
    // MARK: Types

    /// An `Int` raw-value enum, like most server enums.
    enum Fruit: Int, Codable {
        case apple = 1
        case banana = 2
    }

    /// A non-`Codable` raw-value enum, like the enums exposed by the SDK.
    enum Vegetable: UInt8 {
        case carrot = 1
        case pea = 2
        case squash = 3
    }

    /// A `String` raw-value enum.
    enum Color: String {
        case red
    }

    struct Model: Codable, Equatable {
        let fruit: OpenEnum<Fruit>
    }

    struct CollectionModel: Codable {
        let fruits: [OpenEnum<Fruit>]
        let maybe: OpenEnum<Fruit>?
        let missing: OpenEnum<Fruit>?
    }

    // MARK: Tests

    /// `init(from:)` decodes a known raw value as `.known`.
    @Test
    func decode_knownValue() throws {
        let subject = try decode(Model.self, #"{"fruit": 2}"#)
        #expect(subject.fruit == .known(.banana))
        #expect(subject.fruit.knownValue == .banana)
        #expect(subject.fruit.rawValue == 2)
    }

    /// `init(from:)` decodes an unrecognized raw value as `.unknown`, preserving the raw value.
    @Test
    func decode_unknownValue_preservesRawValue() throws {
        let subject = try decode(Model.self, #"{"fruit": 23}"#)
        #expect(subject.fruit == .unknown(23))
        #expect(subject.fruit.knownValue == nil)
        #expect(subject.fruit.rawValue == 23)
    }

    /// `init(from:)` works for array elements and optionals without extra overloads.
    @Test
    func decode_arrayAndOptional() throws {
        let subject = try decode(CollectionModel.self, #"{"fruits": [1, 23, 2], "maybe": 99}"#)
        #expect(subject.fruits == [.known(.apple), .unknown(23), .known(.banana)])
        #expect(subject.fruits.compactMap(\.knownValue) == [.apple, .banana])
        #expect(subject.maybe == .unknown(99))
        #expect(subject.missing == nil)
    }

    /// `init(from:)` can wrap a `RawRepresentable` enum that isn't `Codable`.
    @Test
    func decode_nonCodableEnum() throws {
        let subject = try decode([OpenEnum<Vegetable>].self, "[3, 99]")
        #expect(subject == [.known(.squash), .unknown(99)])
    }

    /// `init(from:)` decodes `String` raw values.
    @Test
    func decode_stringRawValue() throws {
        let subject = try decode([OpenEnum<Color>].self, #"["red", "blue"]"#)
        #expect(subject == [.known(.red), .unknown("blue")])
    }

    /// `init(from:)` throws if the raw value is the wrong JSON type.
    @Test
    func decode_wrongJSONType_throws() {
        #expect(throws: DecodingError.self) {
            try decode(OpenEnum<Fruit>.self, #""apple""#)
        }
    }

    /// `description` describes known and unknown values.
    @Test
    func description() {
        #expect(OpenEnum<Fruit>.known(.apple).description == "apple")
        #expect(OpenEnum<Fruit>.unknown(23).description == "unknown(23)")
    }

    /// `encode(to:)` encodes a known value's raw value.
    @Test
    func encode_knownValue() throws {
        #expect(try encode(Model(fruit: .known(.banana))) == #"{"fruit":2}"#)
    }

    /// `encode(to:)` round-trips an unknown raw value without loss.
    @Test
    func encode_unknownValue_roundTrips() throws {
        let json = #"{"fruit":23}"#
        let subject = try decode(Model.self, json)
        #expect(try encode(subject) == json)
    }

    /// A persisted unknown value resolves to a known value once the enum gains the case.
    @Test
    func encode_persistedUnknown_resolvesWhenCaseIsAdded() throws {
        let persisted = try encode(OpenEnum<Fruit>.unknown(3))
        #expect(try decode(OpenEnum<Vegetable>.self, persisted) == .known(.squash))
    }

    /// `==` and `!=` compare an `OpenEnum` to a known value.
    @Test
    func equalityWithKnownValue() {
        let subject = OpenEnum<Fruit>(.apple)
        #expect(subject == .apple)
        #expect(subject != .banana)
        #expect(OpenEnum<Fruit>(rawValue: 23) == .unknown(23))
        #expect(OpenEnum<Fruit>.unknown(23) != .apple)
    }

    /// `init(rawValue:)` maps a raw value to `.known` or `.unknown`.
    @Test
    func init_rawValue() {
        #expect(OpenEnum<Fruit>(rawValue: 1) == .known(.apple))
        #expect(OpenEnum<Fruit>(rawValue: 5) == .unknown(5))
    }

    // MARK: Private

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(T.self, from: Data(json.utf8))
    }

    private func encode(_ value: some Encodable) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(value)
        return try #require(String(bytes: data, encoding: .utf8))
    }
}
