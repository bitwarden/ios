import TestHelpers
import XCTest

@testable import BitwardenKit

class JSONDecoderBitwardenTests: BitwardenTestCase {
    // MARK: Tests

    /// `JSONDecoder.cxfDecoder` can decode Credential Exchange Format.
    func test_cxfDecoder_decodesISO8601DateWithFractionalSeconds() throws {
        let subject = JSONDecoder.cxfDecoder
        let toDecode = #"{"credentialId":"credential","date":1697790414,"otherKey":"other","rpId":"rp"}"#

        struct JSONBody: Codable, Equatable {
            let credentialId: String
            let date: Date
            let otherKey: String
            let rpId: String
        }

        let body = JSONBody(
            credentialId: "credential",
            date: Date(year: 2023, month: 10, day: 20, hour: 8, minute: 26, second: 54),
            otherKey: "other",
            rpId: "rp"
        )

        XCTAssertEqual(
            try subject
                .decode(JSONBody.self, from: Data(toDecode.utf8)),
            body
        )
    }

    /// `JSONDecoder.defaultDecoder` can decode ISO8601 dates with fractional seconds.
    func test_defaultDecoder_decodesISO8601DateWithFractionalSeconds() {
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
    func test_defaultDecoder_decodesISO8601DateWithoutFractionalSeconds() {
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
    func test_defaultDecoder_decodesInvalidDateThrowsError() {
        let subject = JSONDecoder.defaultDecoder

        func assertThrowsDataCorruptedError(
            dateString: String,
            file: StaticString = #filePath,
            line: UInt = #line
        ) {
            XCTAssertThrowsError(
                try subject.decode(Date.self, from: Data(#""\#(dateString)""#.utf8)),
                file: file,
                line: line
            ) { error in
                XCTAssertTrue(error is DecodingError, file: file, line: line)
                guard case let .dataCorrupted(context) = error as? DecodingError else {
                    return XCTFail("Expected error to be DecodingError.dataCorrupted")
                }
                XCTAssertEqual(
                    context.debugDescription,
                    "Unable to decode date with value '\(dateString)'",
                    file: file,
                    line: line
                )
            }
        }

        assertThrowsDataCorruptedError(dateString: "2023-08-23")
        assertThrowsDataCorruptedError(dateString: "🔒")
        assertThrowsDataCorruptedError(dateString: "date")
    }

    /// `JSONDecoder.pascalOrSnakeCaseDecoder` handles decoding keys that use pascal, snake or
    /// camel case.
    func test_pascalOrSnakeCaseDecoder() throws {
        let json = """
        {
            "camelCase": "camel",
            "PascalCase": "pascal",
            "snake_case": "snake"
        }
        """

        struct Casing: Codable, Equatable {
            let camelCase: String
            let pascalCase: String
            let snakeCase: String
        }

        let subject = JSONDecoder.pascalOrSnakeCaseDecoder
        let casing = try subject.decode(Casing.self, from: Data(json.utf8))

        XCTAssertEqual(casing, Casing(camelCase: "camel", pascalCase: "pascal", snakeCase: "snake"))
    }

    /// `JSONDecoder.snakeCaseDecoder` handles decoding keys that use snake case.
    func test_snakeCaseDecoder() throws {
        let json = """
        {
            "snake_case": "snake"
        }
        """

        struct Casing: Codable, Equatable {
            let snakeCase: String
        }

        let subject = JSONDecoder.snakeCaseDecoder
        let casing = try subject.decode(Casing.self, from: Data(json.utf8))

        XCTAssertEqual(casing, Casing(snakeCase: "snake"))
    }
}
