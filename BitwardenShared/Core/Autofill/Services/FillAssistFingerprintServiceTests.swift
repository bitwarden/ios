import Foundation
import Testing

@testable import BitwardenShared

// MARK: - FillAssistFingerprintServiceTests

struct FillAssistFingerprintServiceTests {
    // MARK: Properties

    let subject = DefaultFillAssistFingerprintService()

    // MARK: Tests

    /// `fingerprint(for:)` is deterministic across an encode-decode-encode round trip, regardless
    /// of dictionary iteration order — a false positive here would incorrectly treat legitimate,
    /// unmodified data as tampered.
    @Test
    func fingerprint_encodingDeterminism_noFalsePositiveAcrossRoundTrip() throws {
        for iteration in 0 ..< 10 {
            let data = FillAssistCachedData(
                cid: "sha256:abc\(iteration)",
                rules: [
                    "example.com": FillAssistHostRules(fields: [
                        "username": [.init(id: "user", name: "user", role: nil, tagName: "input", type: "text")],
                        "password": [.init(id: "pass", name: "pass", role: nil, tagName: "input", type: "password")],
                    ]),
                    "other.com": FillAssistHostRules(fields: [
                        "username": [.init(id: "u2", name: nil, role: nil, tagName: "input", type: nil)],
                        "email": [.init(id: "e2", name: nil, role: nil, tagName: "input", type: nil)],
                    ]),
                    "third.com": FillAssistHostRules(fields: [
                        "otp": [.init(id: "o3", name: nil, role: nil, tagName: nil, type: nil)],
                    ]),
                ],
                sourceUrl: "https://cdn.example.com/rules.json",
            )

            let originalFingerprint = try subject.fingerprint(for: data)
            let roundTripped = try JSONDecoder().decode(FillAssistCachedData.self, from: JSONEncoder().encode(data))
            let roundTrippedFingerprint = try subject.fingerprint(for: roundTripped)

            #expect(originalFingerprint == roundTrippedFingerprint)
        }
    }

    /// `fingerprint(for:)` returns a lowercase hexadecimal SHA-256 digest (64 characters).
    @Test
    func fingerprint_returnsHexSHA256Digest() throws {
        let data = FillAssistCachedData(cid: "sha256:abc", rules: [:], sourceUrl: "https://example.com")

        let result = try subject.fingerprint(for: data)

        #expect(result.count == 64)
        #expect(result == result.lowercased())
    }

    /// `fingerprint(for:)` returns different fingerprints for different data.
    @Test
    func fingerprint_differentData_returnsDifferentFingerprints() throws {
        let first = FillAssistCachedData(cid: "sha256:abc", rules: [:], sourceUrl: "https://example.com")
        let second = FillAssistCachedData(cid: "sha256:def", rules: [:], sourceUrl: "https://example.com")

        #expect(try subject.fingerprint(for: first) != subject.fingerprint(for: second))
    }
}
