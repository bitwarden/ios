import XCTest

@testable import BitwardenKit

class DataTests: BitwardenTestCase {
    // MARK: Tests - base64url encoding

    func test_asBase64urlString() {
        let subject = Data(repeating: 1, count: 32)
        XCTAssertEqual(
            subject.base64urlEncodedString(),
            "AQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQE",
        )
    }

    func test_fromBase64UrlStringPadded() {
        let subject = "9031WCEDOh6ZUGV_-wvUSw=="
        XCTAssertEqual(
            try XCTUnwrap(Data(base64urlEncoded: subject)),
            // swiftformat:disable:next numberFormatting
            Data([0xf7, 0x4d, 0xf5, 0x58, 0x21, 0x03, 0x3a, 0x1e, 0x99, 0x50, 0x65, 0x7f, 0xfb, 0x0b, 0xd4, 0x4b]),
        )
    }

    func test_fromBase64UrlStringUnpadded() {
        let subject = "9031WCEDOh6ZUGV_-wvUSw"
        XCTAssertEqual(
            try XCTUnwrap(Data(base64urlEncoded: subject)),
            // swiftformat:disable:next numberFormatting
            Data([0xf7, 0x4d, 0xf5, 0x58, 0x21, 0x03, 0x3a, 0x1e, 0x99, 0x50, 0x65, 0x7f, 0xfb, 0x0b, 0xd4, 0x4b]),
        )
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
