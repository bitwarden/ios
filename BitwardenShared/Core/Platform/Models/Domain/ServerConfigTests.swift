import Foundation
import XCTest

@testable import BitwardenShared

final class ServerConfigTests: BitwardenTestCase {
    // MARK: Tests

    /// `init` properly converts feature flags
    func test_init_featureFlags() {
        let model = ConfigResponseModel(
            environment: nil,
            featureStates: [
                "vault-onboarding": .bool(true),
                "test-remote-feature-flag": .bool(false),
                "not-a-real-feature-flag": .int(42),
            ],
            gitHash: "123",
            server: nil,
            version: "1.2.3"
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertEqual(subject.featureStates, [.testRemoteFeatureFlag: .bool(false)])
    }

    /// `supportsCipherKeyEncryption()` returns `true` when the server version is equal
    /// to the minimum version that supports cipher key encryption.
    func test_supportsCipherKeyEncryption_equalValidVersion() {
        let model = ConfigResponseModel(
            environment: nil,
            featureStates: [:],
            gitHash: "123",
            server: nil,
            version: "2024.2.0"
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertTrue(subject.supportsCipherKeyEncryption())
    }

    /// `supportsCipherKeyEncryption()` returns `true` when the server version is greater
    /// than the minimum version that supports cipher key encryption.
    func test_supportsCipherKeyEncryption_greaterValidVersion() {
        let model = ConfigResponseModel(
            environment: nil,
            featureStates: [:],
            gitHash: "123",
            server: nil,
            version: "2024.3.15"
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertTrue(subject.supportsCipherKeyEncryption())
    }

    /// `supportsCipherKeyEncryption()` returns `false` when the server version is lesser
    /// than the minimum version that supports cipher key encryption.
    func test_supportsCipherKeyEncryption_lesserThanVersion() {
        let model = ConfigResponseModel(
            environment: nil,
            featureStates: [:],
            gitHash: "123",
            server: nil,
            version: "2023.1.28"
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertFalse(subject.supportsCipherKeyEncryption())
    }

    /// `supportsCipherKeyEncryption()` returns `false` when the server version has wrong format.
    func test_supportsCipherKeyEncryption_wrongFormat() {
        let model = ConfigResponseModel(
            environment: nil,
            featureStates: [:],
            gitHash: "123",
            server: nil,
            version: "20asdfasdf24.2.0"
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertFalse(subject.supportsCipherKeyEncryption())
    }
}
