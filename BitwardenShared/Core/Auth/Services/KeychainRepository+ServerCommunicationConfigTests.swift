// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - KeychainRepositoryServerCommunicationConfigTests

final class KeychainRepositoryServerCommunicationConfigTests: BitwardenTestCase {
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

    // MARK: Tests - Server Communication Config

    /// `deleteServerCommunicationConfig(hostname:)` deletes the correct item via the facade.
    ///
    func test_deleteServerCommunicationConfig() async throws {
        try await subject.deleteServerCommunicationConfig(hostname: "example.com")

        XCTAssertEqual(
            keychainServiceFacade.deleteValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.serverCommunicationConfig(hostname: "example.com").unformattedKey,
        )
    }

    /// `getServerCommunicationConfig(hostname:)` returns the stored config.
    ///
    func test_getServerCommunicationConfig_success() async throws {
        let config = ServerCommunicationConfig(bootstrap: .direct)
        let configData = try JSONEncoder.defaultEncoder.encode(config)
        keychainServiceFacade.getValueReturnValue = String(data: configData, encoding: .utf8)!

        let result = try await subject.getServerCommunicationConfig(hostname: "example.com")

        XCTAssertEqual(result, ServerCommunicationConfig(bootstrap: .direct))
        XCTAssertEqual(
            keychainServiceFacade.getValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.serverCommunicationConfig(hostname: "example.com").unformattedKey,
        )
    }

    /// `getServerCommunicationConfig(hostname:)` returns nil on keyNotFound.
    ///
    func test_getServerCommunicationConfig_notFound_keyNotFound() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.keyNotFound(
            BitwardenKeychainItem.serverCommunicationConfig(hostname: "example.com"),
        )

        let result = try await subject.getServerCommunicationConfig(hostname: "example.com")

        XCTAssertNil(result)
    }

    /// `getServerCommunicationConfig(hostname:)` returns nil when the OS status indicates not found.
    ///
    func test_getServerCommunicationConfig_notFound_osStatus() async throws {
        keychainServiceFacade.getValueThrowableError = KeychainServiceError.osStatusError(errSecItemNotFound)

        let result = try await subject.getServerCommunicationConfig(hostname: "example.com")

        XCTAssertNil(result)
    }

    /// `setServerCommunicationConfig(_:hostname:)` stores the config as JSON via the facade.
    ///
    func test_setServerCommunicationConfig_withConfig() async throws {
        let config = ServerCommunicationConfig(bootstrap: .direct)
        try await subject.setServerCommunicationConfig(config, hostname: "example.com")

        XCTAssertEqual(
            keychainServiceFacade.setValueReceivedArguments?.item.unformattedKey,
            BitwardenKeychainItem.serverCommunicationConfig(hostname: "example.com").unformattedKey,
        )
        let storedValue = try XCTUnwrap(keychainServiceFacade.setValueReceivedArguments?.value)
        let decoded = try JSONDecoder.defaultDecoder.decode(
            ServerCommunicationConfig.self,
            from: XCTUnwrap(storedValue.data(using: .utf8)),
        )
        XCTAssertEqual(decoded, ServerCommunicationConfig(bootstrap: .direct))
    }

    /// `setServerCommunicationConfig(_:hostname:)` deletes the item when config is nil.
    ///
    func test_setServerCommunicationConfig_nilConfig() async throws {
        try await subject.setServerCommunicationConfig(nil, hostname: "example.com")

        XCTAssertEqual(
            keychainServiceFacade.deleteValueReceivedItem?.unformattedKey,
            BitwardenKeychainItem.serverCommunicationConfig(hostname: "example.com").unformattedKey,
        )
    }

    /// `unformattedKey` generates the expected unformatted key for server communication config.
    ///
    func test_unformattedKey_serverCommunicationConfig() {
        let item = BitwardenKeychainItem.serverCommunicationConfig(hostname: "example.com")
        XCTAssertEqual(item.unformattedKey, "serverCommunicationConfig_example.com")
    }
}
