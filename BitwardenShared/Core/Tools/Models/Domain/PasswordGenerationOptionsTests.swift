import XCTest

@testable import BitwardenShared

class PasswordGenerationOptionsTests: BitwardenTestCase {
    // MARK: Tests

    /// `PasswordGenerationOptions` can be decoded from a JSON with all values set.
    func test_decode() throws {
        let json = """
        {
          "allowAmbiguousChar": false,
          "capitalize": true,
          "includeNumber": true,
          "length": 30,
          "lowercase": true,
          "minLowercase": 0,
          "minNumber": 3,
          "minSpecial": 4,
          "minUppercase": 0,
          "number": true,
          "numWords": 5,
          "special": true,
          "type": "passphrase",
          "uppercase": true,
          "wordSeparator": "-"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let subject = try JSONDecoder().decode(PasswordGenerationOptions.self, from: data)
        XCTAssertEqual(
            subject,
            PasswordGenerationOptions(
                allowAmbiguousChar: false,
                capitalize: true,
                includeNumber: true,
                length: 30,
                lowercase: true,
                minLowercase: 0,
                minNumber: 3,
                minSpecial: 4,
                minUppercase: 0,
                number: true,
                numWords: 5,
                special: true,
                type: .passphrase,
                uppercase: true,
                wordSeparator: "-"
            )
        )
    }

    /// `PasswordGenerationOptions` can be decoded from an empty JSON object.
    func test_decode_empty() throws {
        let data = try XCTUnwrap(#"{}"#.data(using: .utf8))
        let subject = try JSONDecoder().decode(PasswordGenerationOptions.self, from: data)
        XCTAssertEqual(subject, PasswordGenerationOptions())
    }
}
