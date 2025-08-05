import TestHelpers
import XCTest

@testable import BitwardenKit

class JSONEncoderBitwardenTests: BitwardenTestCase {
    // MARK: Tests

    /// `JSONEncoder.cxfEncoder` encodes for Credential Exchange Format.
    func test_cxfpEncoder_encodesISO8601DateWithFractionalSeconds() throws {
        let subject = JSONEncoder.cxfEncoder
        subject.outputFormatting = .sortedKeys // added for test consistency so output is ordered.

        struct JSONBody: Codable {
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
        let encodedData = try subject.encode(body)
        let encodedString = String(data: encodedData, encoding: .utf8)
        XCTAssertEqual(
            encodedString,
            #"{"credentialId":"credential","date":1697790414,"otherKey":"other","rpId":"rp"}"#
        )
    }

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
