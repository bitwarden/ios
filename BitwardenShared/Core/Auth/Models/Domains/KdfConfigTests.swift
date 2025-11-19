import XCTest

@testable import BitwardenShared

class KdfConfigTests: BitwardenTestCase {
    // MARK: Tests

    /// `init(kdf:)` initializes `KdfConfig` from `BitwardenSdk.Kdf` when using `argon2id`.
    func test_init_kdf_argon2() {
        let subject = KdfConfig(kdf: .argon2id(iterations: 3, memory: 64, parallelism: 4))
        XCTAssertEqual(
            subject,
            KdfConfig(
                kdfType: .argon2id,
                iterations: 3,
                memory: 64,
                parallelism: 4,
            ),
        )
    }

    /// `init(kdf:)` initializes `KdfConfig` from `BitwardenSdk.Kdf` when using `pbkdf2`.
    func test_init_kdf_pbkdf2() {
        let subject = KdfConfig(kdf: .pbkdf2(iterations: 600_000))
        XCTAssertEqual(
            subject,
            KdfConfig(
                kdfType: .pbkdf2sha256,
                iterations: 600_000,
                memory: nil,
                parallelism: nil,
            ),
        )
    }
}
