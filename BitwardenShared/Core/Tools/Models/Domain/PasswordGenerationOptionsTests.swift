import BitwardenSdk
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
          "wordSeparator": "-",
          "overridePasswordType": false
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
                wordSeparator: "-",
                overridePasswordType: false,
            ),
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

    /// `setMinLowercase(_:)` sets the minimum lowercase, if it isn't already greater.
    func test_setMinLowercase() {
        var subject = PasswordGenerationOptions()
        subject.setMinLowercase(3)
        XCTAssertEqual(subject.minLowercase, 3)

        subject.setMinLowercase(1)
        XCTAssertEqual(subject.minLowercase, 3)

        subject.setMinLowercase(5)
        XCTAssertEqual(subject.minLowercase, 5)
    }

    /// `setMinUppercase(_:)` sets the minimum uppercase, if it isn't already greater.
    func test_setMinUppercase() {
        var subject = PasswordGenerationOptions()
        subject.setMinUppercase(2)
        XCTAssertEqual(subject.minUppercase, 2)

        subject.setMinUppercase(1)
        XCTAssertEqual(subject.minUppercase, 2)

        subject.setMinUppercase(4)
        XCTAssertEqual(subject.minUppercase, 4)
    }

    // MARK: apply(_:)

    /// `apply(_:)` enables character sets required by the request when they are not already set.
    func test_apply_enablesCharacterSets_fromRequest() {
        var subject = PasswordGenerationOptions()
        let request = PasswordGeneratorRequest(
            lowercase: true,
            uppercase: true,
            numbers: true,
            special: true,
            length: 20,
            avoidAmbiguous: true,
            minLowercase: 2,
            minUppercase: 2,
            minNumber: 2,
            minSpecial: 2,
        )
        subject.apply(request)

        XCTAssertTrue(subject.lowercase == true)
        XCTAssertTrue(subject.uppercase == true)
        XCTAssertTrue(subject.number == true)
        XCTAssertTrue(subject.special == true)
        XCTAssertEqual(subject.length, 20)
        XCTAssertEqual(subject.allowAmbiguousChar, false)
        XCTAssertEqual(subject.minLowercase, 2)
        XCTAssertEqual(subject.minUppercase, 2)
        XCTAssertEqual(subject.minNumber, 2)
        XCTAssertEqual(subject.minSpecial, 2)
    }

    /// `apply(_:)` preserves existing minimums when they are already higher than the request.
    func test_apply_preservesHigherMinimums() {
        var subject = PasswordGenerationOptions(
            length: 30,
            minNumber: 5,
            minSpecial: 4,
        )
        let request = PasswordGeneratorRequest(
            lowercase: true,
            uppercase: true,
            numbers: true,
            special: true,
            length: 14,
            avoidAmbiguous: false,
            minLowercase: nil,
            minUppercase: nil,
            minNumber: 1,
            minSpecial: 1,
        )
        subject.apply(request)

        XCTAssertEqual(subject.length, 30)
        XCTAssertEqual(subject.minNumber, 5)
        XCTAssertEqual(subject.minSpecial, 4)
    }

    /// `apply(_:)` raises the length when the request specifies a longer minimum.
    func test_apply_raisesLength() {
        var subject = PasswordGenerationOptions(length: 14)
        let request = PasswordGeneratorRequest(
            lowercase: true,
            uppercase: true,
            numbers: true,
            special: false,
            length: 20,
            avoidAmbiguous: false,
            minLowercase: nil,
            minUppercase: nil,
            minNumber: nil,
            minSpecial: nil,
        )
        subject.apply(request)

        XCTAssertEqual(subject.length, 20)
    }

    /// `apply(_:)` sets `avoidAmbiguous` when either source requires it.
    func test_apply_avoidAmbiguous_eitherSourceTrue() {
        var subject = PasswordGenerationOptions(allowAmbiguousChar: true)
        let request = PasswordGeneratorRequest(
            lowercase: true,
            uppercase: true,
            numbers: true,
            special: false,
            length: 14,
            avoidAmbiguous: true,
            minLowercase: nil,
            minUppercase: nil,
            minNumber: nil,
            minSpecial: nil,
        )
        subject.apply(request)

        XCTAssertEqual(subject.allowAmbiguousChar, false)
    }

    // MARK: passwordGeneratorRequest

    /// `passwordGeneratorRequest` uses sensible defaults for an empty `PasswordGenerationOptions`.
    func test_passwordGeneratorRequest_defaults() {
        let subject = PasswordGenerationOptions()
        let request = subject.passwordGeneratorRequest

        XCTAssertTrue(request.lowercase)
        XCTAssertTrue(request.uppercase)
        XCTAssertTrue(request.numbers)
        XCTAssertFalse(request.special)
        XCTAssertEqual(request.length, 14)
        XCTAssertFalse(request.avoidAmbiguous)
        XCTAssertEqual(request.minLowercase, 1)
        XCTAssertEqual(request.minUppercase, 1)
        XCTAssertEqual(request.minNumber, 1)
        XCTAssertNil(request.minSpecial)
    }

    /// `passwordGeneratorRequest` reflects explicit options correctly.
    func test_passwordGeneratorRequest_explicitValues() {
        let subject = PasswordGenerationOptions(
            allowAmbiguousChar: false,
            length: 20,
            lowercase: false,
            minNumber: 3,
            minSpecial: 2,
            number: true,
            special: true,
            uppercase: true,
        )
        let request = subject.passwordGeneratorRequest

        XCTAssertFalse(request.lowercase)
        XCTAssertTrue(request.uppercase)
        XCTAssertTrue(request.numbers)
        XCTAssertTrue(request.special)
        XCTAssertEqual(request.length, 20)
        XCTAssertTrue(request.avoidAmbiguous)
        XCTAssertNil(request.minLowercase)
        XCTAssertEqual(request.minUppercase, 1)
        XCTAssertEqual(request.minNumber, 3)
        XCTAssertEqual(request.minSpecial, 2)
    }

    // MARK: passphraseGeneratorRequest

    /// `passphraseGeneratorRequest` uses sensible defaults for an empty `PasswordGenerationOptions`.
    func test_passphraseGeneratorRequest_defaults() {
        let subject = PasswordGenerationOptions()
        let request = subject.passphraseGeneratorRequest

        XCTAssertEqual(request.numWords, 3)
        XCTAssertEqual(request.wordSeparator, "-")
        XCTAssertFalse(request.capitalize)
        XCTAssertFalse(request.includeNumber)
    }

    /// `passphraseGeneratorRequest` reflects explicit options correctly.
    func test_passphraseGeneratorRequest_explicitValues() {
        let subject = PasswordGenerationOptions(
            capitalize: true,
            includeNumber: true,
            numWords: 5,
            wordSeparator: "_",
        )
        let request = subject.passphraseGeneratorRequest

        XCTAssertEqual(request.numWords, 5)
        XCTAssertEqual(request.wordSeparator, "_")
        XCTAssertTrue(request.capitalize)
        XCTAssertTrue(request.includeNumber)
    }
}
