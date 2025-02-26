import BitwardenSdk
import XCTest

@testable import BitwardenShared

class KdfConfigProtocolTests: BitwardenTestCase {
    /// `sdkKdf` uses the number of iterations provided when creating a `.pbkdf2sha256` value.
    func test_pbkdf2sha256() {
        let subject = KdfConfig(kdf: .pbkdf2sha256, kdfIterations: 600_000)
        let sdkKdf = subject.sdkKdf

        switch sdkKdf {
        case let .pbkdf2(iterations):
            XCTAssertEqual(iterations, 600_000)
        case .argon2id:
            XCTFail("Generated the incorrect Kdf type: \(sdkKdf)")
        }
    }

    /// `sdkKdf` uses all of the provided values when creating an `.argon2id` value.
    func test_argon2id_allValues() {
        let subject = KdfConfig(kdf: .argon2id, kdfIterations: 600_000, kdfMemory: 32, kdfParallelism: 3)
        let sdkKdf = subject.sdkKdf

        switch sdkKdf {
        case let .argon2id(iterations, memory, parallelism):
            XCTAssertEqual(iterations, 600_000)
            XCTAssertEqual(memory, 32)
            XCTAssertEqual(parallelism, 3)
        case .pbkdf2:
            XCTFail("Generated the incorrect Kdf type: \(sdkKdf)")
        }
    }

    /// `sdkKdf` uses a default value for memory when `nil` when creating an `.argon2id` value.
    func test_argon2id_nilMemory() {
        let subject = KdfConfig(kdf: .argon2id, kdfIterations: 600_000, kdfMemory: nil, kdfParallelism: 3)
        let sdkKdf = subject.sdkKdf

        switch sdkKdf {
        case let .argon2id(iterations, memory, parallelism):
            XCTAssertEqual(iterations, 600_000)
            XCTAssertEqual(memory, NonZeroU32(Constants.kdfArgonMemory))
            XCTAssertEqual(parallelism, 3)
        case .pbkdf2:
            XCTFail("Generated the incorrect Kdf type: \(sdkKdf)")
        }
    }

    /// `sdkKdf` uses a default value for parallelism when `nil` when creating an `.argon2id` value.
    func test_argon2id_nilParallelism() {
        let subject = KdfConfig(kdf: .argon2id, kdfIterations: 600_000, kdfMemory: 32, kdfParallelism: nil)
        let sdkKdf = subject.sdkKdf

        switch sdkKdf {
        case let .argon2id(iterations, memory, parallelism):
            XCTAssertEqual(iterations, 600_000)
            XCTAssertEqual(memory, 32)
            XCTAssertEqual(parallelism, NonZeroU32(Constants.kdfArgonParallelism))
        case .pbkdf2:
            XCTFail("Generated the incorrect Kdf type: \(sdkKdf)")
        }
    }
}
