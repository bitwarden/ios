import XCTest

@testable import BitwardenShared

class JSONDecoderBitwardenTests: BitwardenTestCase {
    // MARK: Tests

    /// `JSONDecoder.defaultDecoder` can decode ISO8601 dates with fractional seconds.
    func test_decode_iso8601DateWithFractionalSeconds() {
        let subject = JSONDecoder.defaultDecoder

        XCTAssertEqual(
            try subject
                .decode(Date.self, from: Data(#""2023-08-18T21:33:31.6366667Z""#.utf8)),
            Date(timeIntervalSince1970: 1_692_394_411.636)
        )
        XCTAssertEqual(
            try subject
                .decode(Date.self, from: Data(#""2023-06-14T13:51:24.45Z""#.utf8)),
            Date(timeIntervalSince1970: 1_686_750_684.450)
        )
    }

    /// `JSONDecoder.defaultDecoder` can decode ISO8601 dates without fractional seconds.
    func test_decode_iso8601DateWithoutFractionalSeconds() {
        let subject = JSONDecoder.defaultDecoder

        XCTAssertEqual(
            try subject
                .decode(Date.self, from: Data(#""2023-08-25T21:33:00Z""#.utf8)),
            Date(timeIntervalSince1970: 1_692_999_180)
        )
        XCTAssertEqual(
            try subject
                .decode(Date.self, from: Data(#""2023-07-12T15:46:12Z""#.utf8)),
            Date(timeIntervalSince1970: 1_689_176_772)
        )
    }

    /// `JSONDecoder.defaultDecoder` will throw an error if an invalid or unsupported date format is
    /// encountered.
    func test_decode_invalidDateThrowsError() {
        let subject = JSONDecoder.defaultDecoder

        XCTAssertThrowsError(
            try subject.decode(Date.self, from: Data(#""2023-08-23""#.utf8))
        ) { error in
            XCTAssertTrue(error is DecodingError)
            guard case let .dataCorrupted(context) = error as? DecodingError else {
                return XCTFail("Expected error to be DecodingError.dataCorrupted")
            }
            XCTAssertEqual(context.debugDescription, "Unable to decode date with value '2023-08-23'")
        }

        XCTAssertThrowsError(
            try subject.decode(Date.self, from: Data(#""🔒""#.utf8))
        ) { error in
            XCTAssertTrue(error is DecodingError)
            guard case let .dataCorrupted(context) = error as? DecodingError else {
                return XCTFail("Expected error to be DecodingError.dataCorrupted")
            }
            XCTAssertEqual(context.debugDescription, "Unable to decode date with value '🔒'")
        }

        XCTAssertThrowsError(
            try subject.decode(Date.self, from: Data(#""date""#.utf8))
        ) { error in
            XCTAssertTrue(error is DecodingError)
            guard case let .dataCorrupted(context) = error as? DecodingError else {
                return XCTFail("Expected error to be DecodingError.dataCorrupted")
            }
            XCTAssertEqual(context.debugDescription, "Unable to decode date with value 'date'")
        }
    }
}
