import XCTest

@testable import BitwardenShared

class AgentAccessRelayURLTests: BitwardenTestCase {
    /// `isValid(_:)` accepts `ws://` and `wss://` URLs with a host.
    func test_isValid() {
        XCTAssertTrue(AgentAccessRelayURL.isValid("ws://localhost:8080"))
        XCTAssertTrue(AgentAccessRelayURL.isValid("wss://ap.lesspassword.dev"))
        XCTAssertTrue(AgentAccessRelayURL.isValid("WSS://example.com/path"))
    }

    /// `isValid(_:)` rejects other schemes and incomplete URLs.
    func test_isValid_invalid() {
        XCTAssertFalse(AgentAccessRelayURL.isValid("https://example.com"))
        XCTAssertFalse(AgentAccessRelayURL.isValid("http://example.com"))
        XCTAssertFalse(AgentAccessRelayURL.isValid("example.com"))
        XCTAssertFalse(AgentAccessRelayURL.isValid("ws://"))
        XCTAssertFalse(AgentAccessRelayURL.isValid(""))
    }

    /// `resolve(stored:environment:)` prefers the stored URL.
    func test_resolve_stored() {
        let url = AgentAccessRelayURL.resolve(
            stored: "wss://stored.example.com",
            environment: [AgentAccessConstants.debugRelayURLEnvironmentKey: "ws://env:1"],
        )

        XCTAssertEqual(url, "wss://stored.example.com")
    }

    /// `resolve(stored:environment:)` falls back to the default when nothing valid is configured.
    func test_resolve_default() {
        XCTAssertEqual(
            AgentAccessRelayURL.resolve(stored: nil, environment: [:]),
            AgentAccessConstants.defaultRelayURL,
        )
        XCTAssertEqual(
            AgentAccessRelayURL.resolve(stored: "https://bad", environment: [:]),
            AgentAccessConstants.defaultRelayURL,
        )
    }

    #if DEBUG
    /// `resolve(stored:environment:)` uses the environment override in debug builds.
    func test_resolve_environment() {
        let url = AgentAccessRelayURL.resolve(
            stored: nil,
            environment: [AgentAccessConstants.debugRelayURLEnvironmentKey: "ws://localhost:8080"],
        )

        XCTAssertEqual(url, "ws://localhost:8080")
    }
    #endif
}
