// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import XCTest

@testable import BitwardenShared

// MARK: - KeychainRepositoryAgentAccessTests

final class KeychainRepositoryAgentAccessTests: BitwardenTestCase {
    // MARK: Properties

    var keychainServiceFacade: MockKeychainServiceFacade!
    var subject: DefaultKeychainRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        keychainServiceFacade = MockKeychainServiceFacade()
        subject = DefaultKeychainRepository(
            keychainService: MockKeychainService(),
            keychainServiceFacade: keychainServiceFacade,
        )
    }

    override func tearDown() {
        super.tearDown()

        keychainServiceFacade = nil
        subject = nil
    }

    // MARK: Tests

    /// `deleteAgentAccessState(userId:)` deletes the correct item via the facade.
    func test_deleteAgentAccessState() async throws {
        try await subject.deleteAgentAccessState(userId: "1")

        XCTAssertEqual(
            keychainServiceFacade.deleteValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.agentAccessState(userId: "1").unformattedKey,
        )
    }

    /// `getAgentAccessState(userId:)` returns the stored state.
    func test_getAgentAccessState_success() async throws {
        let state = AgentAccessUserData(
            identity: Data([1, 2, 3]),
            identityFingerprint: "abc",
            connections: [
                AgentAccessStoredConnection(
                    fingerprint: "def",
                    name: "Agent",
                    cachedAt: 10,
                    lastConnectedAt: 20,
                    transportState: Data([4, 5]),
                ),
            ],
            listeningEnabled: true,
            relayURL: "ws://localhost:8080",
        )
        let data = try JSONEncoder.defaultEncoder.encode(state)
        keychainServiceFacade.getValueReturnValue = String(data: data, encoding: .utf8)!

        let result = try await subject.getAgentAccessState(userId: "1")

        XCTAssertEqual(result, state)
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.agentAccessState(userId: "1").unformattedKey,
        )
    }

    /// `getAgentAccessState(userId:)` returns `nil` when the key isn't found.
    func test_getAgentAccessState_keyNotFound() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(
            BitwardenKeychainItem.agentAccessState(userId: "1"),
        )

        let result = try await subject.getAgentAccessState(userId: "1")

        XCTAssertNil(result)
    }

    /// `getAgentAccessState(userId:)` returns `nil` when the OS status indicates not found.
    func test_getAgentAccessState_osStatusNotFound() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)

        let result = try await subject.getAgentAccessState(userId: "1")

        XCTAssertNil(result)
    }

    /// `setAgentAccessState(_:userId:)` stores the state as JSON via the facade.
    func test_setAgentAccessState() async throws {
        let state = AgentAccessUserData(identity: Data([9]), listeningEnabled: true)

        try await subject.setAgentAccessState(state, userId: "1")

        XCTAssertEqual(
            keychainServiceFacade.setValueReceivedArguments?.item.unformattedKey,
            BitwardenKeychainItem.agentAccessState(userId: "1").unformattedKey,
        )
        let storedValue = try XCTUnwrap(keychainServiceFacade.setValueReceivedArguments?.value)
        let decoded = try JSONDecoder.defaultDecoder.decode(
            AgentAccessUserData.self,
            from: XCTUnwrap(storedValue.data(using: .utf8)),
        )
        XCTAssertEqual(decoded, state)
    }

    /// `unformattedKey` generates the expected key and `protection` allows background access.
    func test_agentAccessState_item() {
        let item = BitwardenKeychainItem.agentAccessState(userId: "1")
        XCTAssertEqual(item.unformattedKey, "agentAccessState_1")
        XCTAssertNil(item.accessControlFlags)
        XCTAssertTrue(CFEqual(item.protection, kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly))
    }
}
