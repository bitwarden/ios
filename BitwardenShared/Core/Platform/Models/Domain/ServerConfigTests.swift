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

    func test_isServerVersionAfter_equalValidVersion() {
        let model = ConfigResponseModel(
            environment: nil,
            featureStates: [:],
            gitHash: "123",
            server: nil,
            version: "2024.2.0"
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertEqual(subject.isServerVersionAfter(), true)
    }

    func test_isServerVersionAfter_greaterValidVersion() {
        let model = ConfigResponseModel(
            environment: nil,
            featureStates: [:],
            gitHash: "123",
            server: nil,
            version: "2024.3.15"
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertEqual(subject.isServerVersionAfter(), true)
    }

    func test_isServerVersionAfter_lesserThanVersion() {
        let model = ConfigResponseModel(
            environment: nil,
            featureStates: [:],
            gitHash: "123",
            server: nil,
            version: "2023.1.28"
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertEqual(subject.isServerVersionAfter(), false)
    }

    func test_isServerVersionAfter_legacyServerVersion() {
        let model = ConfigResponseModel(
            environment: nil,
            featureStates: [:],
            gitHash: "123",
            server: nil,
            version: "2022.2.0-release"
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertEqual(subject.isServerVersionAfter(), false)
    }

    func test_isServerVersionAfter_empty() {
        let model = ConfigResponseModel(
            environment: nil,
            featureStates: [:],
            gitHash: "123",
            server: nil,
            version: ""
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertEqual(subject.isServerVersionAfter(), false)
    }

    func test_isServerVersionAfter_wrongFormat() {
        let model = ConfigResponseModel(
            environment: nil,
            featureStates: [:],
            gitHash: "123",
            server: nil,
            version: "2024"
        )

        let subject = ServerConfig(date: Date(), responseModel: model)
        XCTAssertEqual(subject.isServerVersionAfter(), false)
    }
}
