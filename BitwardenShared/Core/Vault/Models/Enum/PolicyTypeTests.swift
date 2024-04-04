import XCTest

@testable import BitwardenShared

class PolicyTypeTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(from:)` decodes an integer value to the `PolicyType` enum.
    func test_init_decoder() {
        XCTAssertEqual(
            try JSONDecoder().decode(PolicyType.self, from: #"0"#.data(using: .utf8)!),
            PolicyType.twoFactorAuthentication
        )
        XCTAssertEqual(
            try JSONDecoder().decode(PolicyType.self, from: #"1"#.data(using: .utf8)!),
            PolicyType.masterPassword
        )
        XCTAssertEqual(
            try JSONDecoder().decode(PolicyType.self, from: #"10"#.data(using: .utf8)!),
            PolicyType.disablePersonalVaultExport
        )
    }

    /// `init(from:)` decodes an invalid or unknown value as `PolicyType.unknown`.
    func test_init_decoder_invalidValue() {
        XCTAssertEqual(
            try JSONDecoder().decode(PolicyType.self, from: #"-1"#.data(using: .utf8)!),
            PolicyType.unknown
        )
        XCTAssertEqual(
            try JSONDecoder().decode(PolicyType.self, from: #"9999"#.data(using: .utf8)!),
            PolicyType.unknown
        )
    }
}
