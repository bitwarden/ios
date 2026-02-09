import XCTest

@testable import BitwardenKit

class DataTests: BitwardenTestCase {
    // MARK: Tests - base64url encoding

    /// `base64urlEncodedString()` converts a Data object to a base64url-encoded String.
    func test_asBase64urlString() {
        let subject = Data(repeating: 1, count: 32)
        XCTAssertEqual(
            subject.base64urlEncodedString(),
            "AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE",
        )
    }

    /// `Data(base64urlEncoded:)` decodes a padded base64url-encoded String into Data.
    func test_fromBase64urlString_padded() {
        let subject = "9031WCEDOh6ZUGV_-wvUSw=="
        XCTAssertEqual(
            try XCTUnwrap(Data(base64urlEncoded: subject)),
            // swiftformat:disable:next numberFormatting
            Data([0xf7, 0x4d, 0xf5, 0x58, 0x21, 0x03, 0x3a, 0x1e, 0x99, 0x50, 0x65, 0x7f, 0xfb, 0x0b, 0xd4, 0x4b]),
        )
    }

    /// `Data(base64urlEncoded:)` decodes an unpadded base64url-encoded String into Data.
    func test_fromBase64urlString_unpadded() {
        let subject = "-_4"
        XCTAssertEqual(
            try XCTUnwrap(Data(base64urlEncoded: subject)),
            // swiftformat:disable:next numberFormatting
            Data([0xfb, 0xfe]),
        )
    }

    /// `Data(base64urlEncoded:)` throws an error for strings with invalid length.
    func test_fromBase64urlString_invalidLength() {
        let subject = "ABCDE" // length 5, which is invalid (5 % 4 == 1)
        XCTAssertThrowsError(try Data(base64urlEncoded: subject)) { error in
            XCTAssertEqual(error as? URLDecodingError, .invalidLength)
        }
    }

    // MARK: Tests - Hex String

    /// `asHexString()` converts the Data object into a hex formatted string.
    func test_asHexString() {
        let subject = Data(repeating: 1, count: 32)
        XCTAssertEqual(
            subject.asHexString(),
            "0101010101010101010101010101010101010101010101010101010101010101",
        )
    }
}
