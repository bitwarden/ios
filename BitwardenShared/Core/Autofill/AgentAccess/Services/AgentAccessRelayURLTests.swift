import XCTest

@testable import BitwardenShared

class AgentAccessRelayURLTests: BitwardenTestCase {
    /// `isValid(_:allowsInsecure:)` accepts `wss://` URLs with a host.
    func test_isValid() {
        XCTAssertTrue(AgentAccessRelayURL.isValid("wss://ap.lesspassword.dev", allowsInsecure: false))
        XCTAssertTrue(AgentAccessRelayURL.isValid("WSS://example.com/path", allowsInsecure: false))
    }

    /// `isValid(_:allowsInsecure:)` rejects `ws://` URLs unless insecure URLs are allowed.
    func test_isValid_insecure() {
        XCTAssertFalse(AgentAccessRelayURL.isValid("ws://localhost:8080", allowsInsecure: false))
        XCTAssertTrue(AgentAccessRelayURL.isValid("ws://localhost:8080", allowsInsecure: true))
        XCTAssertTrue(AgentAccessRelayURL.isValid("wss://example.com", allowsInsecure: true))
    }

    /// `isValid(_:allowsInsecure:)` rejects other schemes and incomplete URLs.
    func test_isValid_invalid() {
        for allowsInsecure in [false, true] {
            XCTAssertFalse(AgentAccessRelayURL.isValid("https://example.com", allowsInsecure: allowsInsecure))
            XCTAssertFalse(AgentAccessRelayURL.isValid("http://example.com", allowsInsecure: allowsInsecure))
            XCTAssertFalse(AgentAccessRelayURL.isValid("example.com", allowsInsecure: allowsInsecure))
            XCTAssertFalse(AgentAccessRelayURL.isValid("wss://", allowsInsecure: allowsInsecure))
            XCTAssertFalse(AgentAccessRelayURL.isValid("", allowsInsecure: allowsInsecure))
        }
    }

    /// `allowsInsecure` is only true in debug builds.
    func test_allowsInsecure() {
        #if DEBUG
        XCTAssertTrue(AgentAccessRelayURL.allowsInsecure)
        #else
        XCTAssertFalse(AgentAccessRelayURL.allowsInsecure)
        #endif
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
