import Foundation
import Testing

@testable import BitwardenKit

struct AnyCodableTests {
    // MARK: Decode Tests

    /// `AnyCodable` can be used to decode JSON.
    @Test
    func decode() throws {
        let json = """
        {
          "minComplexity": null,
          "minLength": 12,
          "requireUpper": false,
          "requireLower": true,
          "requireNumbers": false,
          "requireSpecial": false,
          "enforceOnLogin": false,
          "type": "password",
          "minutes": 1.5
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let dictionary = try JSONDecoder().decode([String: AnyCodable].self, from: jsonData)

        #expect(
            dictionary == [
                "minComplexity": AnyCodable.null,
                "minLength": AnyCodable.int(12),
                "requireUpper": AnyCodable.bool(false),
                "requireLower": AnyCodable.bool(true),
                "requireNumbers": AnyCodable.bool(false),
                "requireSpecial": AnyCodable.bool(false),
                "enforceOnLogin": AnyCodable.bool(false),
                "type": AnyCodable.string("password"),
                "minutes": AnyCodable.double(1.5),
            ],
        )
    }

    /// `AnyCodable` can decode a JSON array of values, e.g. a Send Controls policy's
    /// `allowedSendTypes` field.
    @Test
    func decode_array() throws {
        let json = """
        {
          "disableSend": false,
          "whoCanAccess": 1,
          "allowedDomains": null,
          "disableHideEmail": false,
          "allowedSendTypes": [0, 1],
          "deletionHours": null
        }
        """

        let jsonData = try #require(json.data(using: .utf8))
        let dictionary = try JSONDecoder().decode([String: AnyCodable].self, from: jsonData)

        #expect(dictionary["allowedSendTypes"] == .array([.int(0), .int(1)]))
    }

    /// `AnyCodable` can decode a nested JSON object value.
    @Test
    func decode_dictionary() throws {
        let json = #"{"nested": {"a": 1, "b": true}}"#

        let jsonData = try #require(json.data(using: .utf8))
        let dictionary = try JSONDecoder().decode([String: AnyCodable].self, from: jsonData)

        #expect(dictionary["nested"] == .dictionary(["a": .int(1), "b": .bool(true)]))
    }

    // MARK: Encode Tests

    /// `AnyCodable` can be used to encode JSON.
    @Test
    func encode() throws {
        let dictionary: [String: AnyCodable] = [
            "minComplexity": AnyCodable.null,
            "minLength": AnyCodable.int(12),
            "requireUpper": AnyCodable.bool(false),
            "requireLower": AnyCodable.bool(true),
            "requireNumbers": AnyCodable.bool(false),
            "requireSpecial": AnyCodable.bool(false),
            "enforceOnLogin": AnyCodable.bool(false),
            "type": AnyCodable.string("password"),
            "minutes": AnyCodable.double(1.5),
        ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(dictionary)
        let json = String(data: jsonData, encoding: .utf8)

        #expect(
            json == """
            {
              "enforceOnLogin" : false,
              "minComplexity" : null,
              "minLength" : 12,
              "minutes" : 1.5,
              "requireLower" : true,
              "requireNumbers" : false,
              "requireSpecial" : false,
              "requireUpper" : false,
              "type" : "password"
            }
            """,
        )
    }

    /// `AnyCodable` can encode a JSON array of values.
    @Test
    func encode_array() throws {
        let dictionary: [String: AnyCodable] = ["allowedSendTypes": .array([.int(0), .int(1)])]

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(dictionary)
        let json = String(data: jsonData, encoding: .utf8)

        #expect(json == #"{"allowedSendTypes":[0,1]}"#)
    }

    /// `AnyCodable` can encode a nested JSON object value.
    @Test
    func encode_dictionary() throws {
        let dictionary: [String: AnyCodable] = ["nested": .dictionary(["a": .int(1)])]

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(dictionary)
        let json = String(data: jsonData, encoding: .utf8)

        #expect(json == #"{"nested":{"a":1}}"#)
    }

    // MARK: Value Tests

    /// `arrayValue` returns the array associated value if the type is an `array`.
    @Test
    func arrayValue() {
        #expect(AnyCodable.array([.int(0), .int(1)]).arrayValue == [.int(0), .int(1)])

        #expect(AnyCodable.bool(true).arrayValue == nil)
        #expect(AnyCodable.dictionary(["a": .int(1)]).arrayValue == nil)
        #expect(AnyCodable.null.arrayValue == nil)
        #expect(AnyCodable.string("abc").arrayValue == nil)
    }

    /// `boolValue` returns the bool associated value if the type is a `bool`.
    @Test
    func boolValue() {
        #expect(AnyCodable.bool(true).boolValue == true)
        #expect(AnyCodable.bool(false).boolValue == false)

        #expect(AnyCodable.int(2).boolValue == nil)
        #expect(AnyCodable.null.boolValue == nil)
        #expect(AnyCodable.string("abc").boolValue == nil)
    }

    /// `dictionaryValue` returns the dictionary associated value if the type is a `dictionary`.
    @Test
    func dictionaryValue() {
        #expect(AnyCodable.dictionary(["a": .int(1)]).dictionaryValue == ["a": .int(1)])

        #expect(AnyCodable.array([.int(1)]).dictionaryValue == nil)
        #expect(AnyCodable.bool(true).dictionaryValue == nil)
        #expect(AnyCodable.null.dictionaryValue == nil)
        #expect(AnyCodable.string("abc").dictionaryValue == nil)
    }

    /// `doubleValue` returns the double associated value if the type is a `double` or could be
    /// converted to `Double`.
    @Test
    func doubleValue() {
        #expect(AnyCodable.bool(true).doubleValue == 1)
        #expect(AnyCodable.bool(false).doubleValue == 0)

        #expect(AnyCodable.double(2).doubleValue == 2)
        #expect(AnyCodable.double(3.1).doubleValue == 3.1)
        #expect(AnyCodable.double(3.8).doubleValue == 3.8)
        #expect(AnyCodable.double(-5.5).doubleValue == -5.5)

        #expect(AnyCodable.int(1).doubleValue == 1)
        #expect(AnyCodable.int(5).doubleValue == 5)
        #expect(AnyCodable.int(15).doubleValue == 15)

        #expect(AnyCodable.null.doubleValue == nil)

        #expect(AnyCodable.string("1").doubleValue == 1)
        #expect(AnyCodable.string("1.5").doubleValue == 1.5)
        #expect(AnyCodable.string("abc").doubleValue == nil)
    }

    /// `intValue` returns the int associated value if the type is an `int` or could be converted
    /// to `Int`.
    @Test
    func intValue() {
        #expect(AnyCodable.bool(true).intValue == 1)
        #expect(AnyCodable.bool(false).intValue == 0)

        #expect(AnyCodable.double(2).intValue == 2)
        #expect(AnyCodable.double(3.1).intValue == 3)
        #expect(AnyCodable.double(3.8).intValue == 3)
        #expect(AnyCodable.double(-5.5).intValue == -5)

        #expect(AnyCodable.int(1).intValue == 1)
        #expect(AnyCodable.int(5).intValue == 5)
        #expect(AnyCodable.int(15).intValue == 15)

        #expect(AnyCodable.null.intValue == nil)

        #expect(AnyCodable.string("1").intValue == 1)
        #expect(AnyCodable.string("1.5").intValue == nil)
        #expect(AnyCodable.string("abc").intValue == nil)
    }

    /// `stringValue` returns the string associated value if the type is a `string`.
    @Test
    func stringValue() {
        #expect(AnyCodable.string("abc").stringValue == "abc")
        #expect(AnyCodable.string("example").stringValue == "example")

        #expect(AnyCodable.bool(false).stringValue == nil)
        #expect(AnyCodable.int(2).stringValue == nil)
        #expect(AnyCodable.null.stringValue == nil)
    }
}
