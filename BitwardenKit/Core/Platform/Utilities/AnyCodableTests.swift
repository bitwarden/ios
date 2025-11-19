import XCTest

@testable import BitwardenKit

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
          "type": "password",
          "minutes": 1.5
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
                "minutes": AnyCodable.double(1.5),
            ],
        )
    }

    /// `doubleValue` returns the double associated value if the type is a `double` or could be
    /// converted to `Double`.
    func test_doubleValue() {
        XCTAssertEqual(AnyCodable.bool(true).doubleValue, 1)
        XCTAssertEqual(AnyCodable.bool(false).doubleValue, 0)

        XCTAssertEqual(AnyCodable.double(2).doubleValue, 2)
        XCTAssertEqual(AnyCodable.double(3.1).doubleValue, 3.1)
        XCTAssertEqual(AnyCodable.double(3.8).doubleValue, 3.8)
        XCTAssertEqual(AnyCodable.double(-5.5).doubleValue, -5.5)

        XCTAssertEqual(AnyCodable.int(1).doubleValue, 1)
        XCTAssertEqual(AnyCodable.int(5).doubleValue, 5)
        XCTAssertEqual(AnyCodable.int(15).doubleValue, 15)

        XCTAssertNil(AnyCodable.null.doubleValue)

        XCTAssertEqual(AnyCodable.string("1").doubleValue, 1)
        XCTAssertEqual(AnyCodable.string("1.5").doubleValue, 1.5)
        XCTAssertNil(AnyCodable.string("abc").doubleValue)
    }

    /// `AnyCodable` can be used to encode JSON.
    func test_encode() throws {
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

        XCTAssertEqual(
            json,
            """
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

    /// `intValue` returns the int associated value if the type is an `int` or could be converted
    /// to `Int`.
    func test_intValue() {
        XCTAssertEqual(AnyCodable.bool(true).intValue, 1)
        XCTAssertEqual(AnyCodable.bool(false).intValue, 0)

        XCTAssertEqual(AnyCodable.double(2).intValue, 2)
        XCTAssertEqual(AnyCodable.double(3.1).intValue, 3)
        XCTAssertEqual(AnyCodable.double(3.8).intValue, 3)
        XCTAssertEqual(AnyCodable.double(-5.5).intValue, -5)

        XCTAssertEqual(AnyCodable.int(1).intValue, 1)
        XCTAssertEqual(AnyCodable.int(5).intValue, 5)
        XCTAssertEqual(AnyCodable.int(15).intValue, 15)

        XCTAssertNil(AnyCodable.null.intValue)

        XCTAssertEqual(AnyCodable.string("1").intValue, 1)
        XCTAssertNil(AnyCodable.string("1.5").intValue)
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
