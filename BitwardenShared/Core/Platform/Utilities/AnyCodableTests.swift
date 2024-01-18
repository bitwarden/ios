import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AnyCodableTests: BitwardenTestCase {
    // MARK: Properties

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
}
