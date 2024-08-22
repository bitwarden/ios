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
}
