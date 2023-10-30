import XCTest

@testable import BitwardenShared

class JSONEncoderBitwardenTests: BitwardenTestCase {
    // MARK: Tests

    /// `JSONEncoder.defaultEncoder` can encode ISO8601 dates without fractional seconds.
    func test_defaultEncoder_encodesISO8601DateWithoutFractionalSeconds() throws {
        let subject = JSONEncoder.defaultEncoder

        struct JSONBody: Codable {
            let date: Date
        }

        let encodedData = try subject.encode(JSONBody(date: Date(year: 2023, month: 10, day: 31)))
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            #"{"date":"2023-10-31T00:00:00.000Z"}"#
        )
    }

    /// `JSONEncoder.defaultEncoder` can encode ISO8601 dates with fractional seconds.
    func test_defaultEncoder_encodesISO8601DateWithFractionalSeconds() throws {
        let subject = JSONEncoder.defaultEncoder

        struct JSONBody: Codable {
            let date: Date
        }

        let body = JSONBody(
            date: Date(year: 2023, month: 10, day: 20, hour: 8, minute: 26, second: 54, nanosecond: 482_000_000)
        )
        let encodedData = try subject.encode(body)
        XCTAssertEqual(
            String(data: encodedData, encoding: .utf8),
            #"{"date":"2023-10-20T08:26:54.482Z"}"#
        )
    }
}
