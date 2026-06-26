import Foundation
import Testing

@testable import BitwardenShared

// MARK: - CompactDecodableTests

struct CompactDecodableTests {
    // MARK: Types

    struct Model: Codable, Equatable {
        @CompactDecodable var entries: [String: Int]?
    }

    // MARK: Tests - Decoding

    /// `@CompactDecodable` decodes a present key with non-null values into a populated dictionary.
    @Test
    func decode_presentKey_populatesEntries() throws {
        let json = #"{"entries": {"a": 1, "b": 2}}"#
        let subject = try JSONDecoder().decode(Model.self, from: Data(json.utf8))
        #expect(subject.entries == ["a": 1, "b": 2])
    }

    /// `@CompactDecodable` strips null-valued entries, keeping only non-null values.
    @Test
    func decode_nullValuesStripped() throws {
        let json = #"{"entries": {"a": 1, "b": null, "c": 3}}"#
        let subject = try JSONDecoder().decode(Model.self, from: Data(json.utf8))
        #expect(subject.entries == ["a": 1, "c": 3])
    }

    /// `@CompactDecodable` produces `nil` when the key is absent from the JSON.
    @Test
    func decode_missingKey_producesNil() throws {
        let json = #"{}"#
        let subject = try JSONDecoder().decode(Model.self, from: Data(json.utf8))
        #expect(subject.entries == nil)
    }

    /// `@CompactDecodable` produces `nil` when the key's value is JSON `null`.
    @Test
    func decode_nullValue_producesNil() throws {
        let json = #"{"entries": null}"#
        let subject = try JSONDecoder().decode(Model.self, from: Data(json.utf8))
        #expect(subject.entries == nil)
    }

    /// `@CompactDecodable` produces an empty dictionary when all entries are null.
    @Test
    func decode_allNullEntries_producesEmptyDictionary() throws {
        let json = #"{"entries": {"a": null, "b": null}}"#
        let subject = try JSONDecoder().decode(Model.self, from: Data(json.utf8))
        #expect(subject.entries?.isEmpty == true)
    }

    // MARK: Tests - Encoding

    /// `@CompactDecodable` encodes a populated dictionary as a JSON object.
    @Test
    func encode_populatedEntries() throws {
        let subject = Model(entries: ["a": 1])
        let data = try JSONEncoder().encode(subject)
        let decoded = try JSONDecoder().decode(Model.self, from: data)
        #expect(decoded.entries == ["a": 1])
    }

    /// `@CompactDecodable` encodes `nil` entries as `null` in JSON.
    @Test
    func encode_nilEntries() throws {
        let subject = Model(entries: nil)
        let data = try JSONEncoder().encode(subject)
        let decoded = try JSONDecoder().decode(Model.self, from: data)
        #expect(decoded.entries == nil)
    }
}
