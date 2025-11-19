import BitwardenKit
import BitwardenSdk
import XCTest

@testable import BitwardenShared

class KdfConfigProtocolTests: BitwardenTestCase {
    /// `sdkKdf` uses the number of iterations provided when creating a `.pbkdf2sha256` value.
    func test_pbkdf2sha256() {
        let subject = KdfConfig(kdfType: .pbkdf2sha256, iterations: 600_000)
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
        let subject = KdfConfig(kdfType: .argon2id, iterations: 600_000, memory: 32, parallelism: 3)
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
        let subject = KdfConfig(kdfType: .argon2id, iterations: 600_000, memory: nil, parallelism: 3)
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
        let subject = KdfConfig(kdfType: .argon2id, iterations: 600_000, memory: 32, parallelism: nil)
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
