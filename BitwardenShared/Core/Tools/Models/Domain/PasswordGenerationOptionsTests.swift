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

    /// `setMinLength(_:)` sets the length, if it isn't already greater than the specified value.
    func test_setMinLength() {
        var subject = PasswordGenerationOptions()
        subject.setMinLength(30)
        XCTAssertEqual(subject.length, 30)

        subject.setMinLength(10)
        XCTAssertEqual(subject.length, 30)

        subject.setMinLength(50)
        XCTAssertEqual(subject.length, 50)
    }

    /// `setMinNumbers(_:)` sets the minimum numbers, if it isn't already greater than the specified value.
    func test_setMinNumbers() {
        var subject = PasswordGenerationOptions()
        subject.setMinNumbers(3)
        XCTAssertEqual(subject.minNumber, 3)

        subject.setMinNumbers(1)
        XCTAssertEqual(subject.minNumber, 3)

        subject.setMinNumbers(5)
        XCTAssertEqual(subject.minNumber, 5)
    }

    /// `setMinNumberWords(_:)` sets the minimum number of words, if it isn't already greater than
    /// the specified value.
    func test_setMinNumberWords() {
        var subject = PasswordGenerationOptions()
        subject.setMinNumberWords(3)
        XCTAssertEqual(subject.numWords, 3)

        subject.setMinNumberWords(1)
        XCTAssertEqual(subject.numWords, 3)

        subject.setMinNumberWords(5)
        XCTAssertEqual(subject.numWords, 5)
    }

    /// `setMinSpecial(_:)` sets the minimum number of special characters, if it isn't already
    /// greater than the specified value.
    func test_setMinSpecial() {
        var subject = PasswordGenerationOptions()
        subject.setMinSpecial(3)
        XCTAssertEqual(subject.minSpecial, 3)

        subject.setMinSpecial(1)
        XCTAssertEqual(subject.minSpecial, 3)

        subject.setMinSpecial(5)
        XCTAssertEqual(subject.minSpecial, 5)
    }
}
