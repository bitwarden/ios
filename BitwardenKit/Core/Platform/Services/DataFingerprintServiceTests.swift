import Foundation
import Testing

@testable import BitwardenKit

// MARK: - DataFingerprintServiceTests

struct DataFingerprintServiceTests {
    // MARK: Types

    private struct TestData: Codable, Equatable {
        let id: String
        let values: [String: [String]]
    }

    // MARK: Properties

    let subject = DefaultDataFingerprintService()

    // MARK: Tests

    /// `fingerprint(for:)` is deterministic across an encode-decode-encode round trip, regardless
    /// of dictionary iteration order — a false positive here would incorrectly treat legitimate,
    /// unmodified data as tampered.
    @Test
    func fingerprint_encodingDeterminism_noFalsePositiveAcrossRoundTrip() throws {
        for iteration in 0 ..< 10 {
            let data = TestData(
                id: "id\(iteration)",
                values: [
                    "a": ["1", "2"],
                    "b": ["3"],
                    "c": ["4", "5", "6"],
                ],
            )

            let originalFingerprint = try subject.fingerprint(for: data)
            let roundTripped = try JSONDecoder().decode(TestData.self, from: JSONEncoder().encode(data))
            let roundTrippedFingerprint = try subject.fingerprint(for: roundTripped)

            #expect(originalFingerprint == roundTrippedFingerprint)
        }
    }

    /// `fingerprint(for:)` returns a lowercase hexadecimal SHA-256 digest (64 characters).
    @Test
    func fingerprint_returnsHexSHA256Digest() throws {
        let data = TestData(id: "abc", values: [:])

        let result = try subject.fingerprint(for: data)

        #expect(result.count == 64)
        #expect(result == result.lowercased())
    }

    /// `fingerprint(for:)` returns different fingerprints for different data.
    @Test
    func fingerprint_differentData_returnsDifferentFingerprints() throws {
        let first = TestData(id: "abc", values: [:])
        let second = TestData(id: "def", values: [:])

        #expect(try subject.fingerprint(for: first) != subject.fingerprint(for: second))
    }
}
