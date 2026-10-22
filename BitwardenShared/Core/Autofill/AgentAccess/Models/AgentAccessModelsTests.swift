import BitwardenKit
import XCTest

@testable import BitwardenShared

class AgentAccessModelsTests: BitwardenTestCase {
    /// `AgentAccessQuery.displayValue` returns the raw value.
    func test_query_displayValue() {
        XCTAssertEqual(AgentAccessQuery.domain("Example.com").displayValue, "Example.com")
        XCTAssertEqual(AgentAccessQuery.id("abc").displayValue, "abc")
        XCTAssertEqual(AgentAccessQuery.search("Foo").displayValue, "Foo")
    }

    /// `AgentAccessQuery.matchKey` ignores case for domains and searches, but not for IDs.
    func test_query_matchKey() {
        XCTAssertEqual(AgentAccessQuery.domain("Example.com").matchKey, "domain:example.com")
        XCTAssertEqual(AgentAccessQuery.search("Foo").matchKey, "search:foo")
        XCTAssertEqual(AgentAccessQuery.id("AbC").matchKey, "id:AbC")
        XCTAssertNotEqual(AgentAccessQuery.domain("a").matchKey, AgentAccessQuery.search("a").matchKey)
    }

    /// `AgentAccessConnection.displayName` falls back to the fingerprint prefix.
    func test_connection_displayName() {
        let fingerprint = String(repeating: "ab", count: 32)
        var connection = AgentAccessConnection(
            fingerprint: fingerprint,
            name: "Codex",
            pairedAt: Date(),
            lastConnectedAt: Date(),
        )
        XCTAssertEqual(connection.displayName, "Codex")

        connection.name = ""
        XCTAssertEqual(connection.displayName, "abababab")

        connection.name = nil
        XCTAssertEqual(connection.displayName, "abababab")
    }

    /// `AgentAccessUserData` decodes old data that is missing newer fields.
    func test_userData_decodesPartialJSON() throws {
        let data = try JSONDecoder().decode(AgentAccessUserData.self, from: Data("{}".utf8))

        XCTAssertEqual(data, AgentAccessUserData())
    }

    /// `AgentAccessPushNotification` decodes the Pascal case payload the server sends.
    func test_pushNotification_decodesPascalCase() throws {
        let json = Data("{\"Fingerprint\":\"abc\",\"UserId\":\"user\"}".utf8)

        let decoded = try JSONDecoder.pascalOrSnakeCaseDecoder.decode(AgentAccessPushNotification.self, from: json)

        XCTAssertEqual(decoded, AgentAccessPushNotification(fingerprint: "abc", userId: "user"))
    }

    /// The push type and feature flag match the server contract.
    func test_contractValues() {
        XCTAssertEqual(NotificationType.agentAccessRequest.rawValue, 30)
        XCTAssertEqual(FeatureFlag.agentAccess.rawValue, "ai-agent-access")
        XCTAssertTrue(FeatureFlag.allCases.contains(.agentAccess))
    }

    #if DEBUG
    /// The feature flag defaults on in debug builds.
    func test_featureFlag_debugInitialValue() {
        XCTAssertEqual(FeatureFlag.agentAccess.initialValue, .bool(true))
    }
    #endif
}
