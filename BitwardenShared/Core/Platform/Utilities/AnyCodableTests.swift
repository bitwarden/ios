import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AnyCodableTests: BitwardenTestCase {
    // MARK: Properties

    /// `boolValue` returns the bool associated value if the type is a `bool`.
    func test_boolValue() {
        XCTAssertEqual(AnyCodable.bool(true).boolValue, true)
        XCTAssertEqual(AnyCodable.bool(false).boolValue, false)

        XCTAssertNil(AnyCodable.int(2).boolValue)
        XCTAssertNil(AnyCodable.null.boolValue)
        XCTAssertNil(AnyCodable.string("abc").boolValue)
    }

    /// `AnyCodable` can be used to decode JSON.
    func test_decode() throws {
        let json = """
        {
          "minComplexity": null,
          "minLength": 12,
          "requireUpper": false,
          "requireLower": true,
          "requireNumbers": false,
          "requireSpecial": false,
          "enforceOnLogin": false,
          "type": "password"
        }
        """

        let jsonData = try XCTUnwrap(json.data(using: .utf8))
        let dictionary = try JSONDecoder().decode([String: AnyCodable].self, from: jsonData)

        XCTAssertEqual(
            dictionary,
            [
                "minComplexity": AnyCodable.null,
                "minLength": AnyCodable.int(12),
                "requireUpper": AnyCodable.bool(false),
                "requireLower": AnyCodable.bool(true),
                "requireNumbers": AnyCodable.bool(false),
                "requireSpecial": AnyCodable.bool(false),
                "enforceOnLogin": AnyCodable.bool(false),
                "type": AnyCodable.string("password"),
            ]
        )
    }

    /// `AnyCodable` can be used to encode JSON.
    func testEncode() throws {
        let dictionary: [String: AnyCodable] = [
            "minComplexity": AnyCodable.null,
            "minLength": AnyCodable.int(12),
            "requireUpper": AnyCodable.bool(false),
            "requireLower": AnyCodable.bool(true),
            "requireNumbers": AnyCodable.bool(false),
            "requireSpecial": AnyCodable.bool(false),
            "enforceOnLogin": AnyCodable.bool(false),
            "type": AnyCodable.string("password"),
        ]

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(dictionary)
        let json = String(data: jsonData, encoding: .utf8)

        XCTAssertEqual(
            json,
            """
            {
              "enforceOnLogin" : false,
              "minComplexity" : null,
              "minLength" : 12,
              "requireLower" : true,
              "requireNumbers" : false,
              "requireSpecial" : false,
              "requireUpper" : false,
              "type" : "password"
            }
            """
        )
    }

    /// `intValue` returns the int associated value if the type is an `int`.
    func test_intValue() {
        XCTAssertEqual(AnyCodable.int(1).intValue, 1)
        XCTAssertEqual(AnyCodable.int(5).intValue, 5)

        XCTAssertNil(AnyCodable.bool(false).intValue)
        XCTAssertNil(AnyCodable.null.intValue)
        XCTAssertNil(AnyCodable.string("abc").intValue)
    }

    /// `stringValue` returns the string associated value if the type is a `string`.
    func test_stringValue() {
        XCTAssertEqual(AnyCodable.string("abc").stringValue, "abc")
        XCTAssertEqual(AnyCodable.string("example").stringValue, "example")

        XCTAssertNil(AnyCodable.bool(false).stringValue)
        XCTAssertNil(AnyCodable.int(2).stringValue)
        XCTAssertNil(AnyCodable.null.stringValue)
    }
}
