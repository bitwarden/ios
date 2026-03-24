// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared

// MARK: - KeychainRepositoryServerCommunicationConfigTests

final class KeychainRepositoryServerCommunicationConfigTests: BitwardenTestCase {
    // MARK: Properties

    var appIDSettingsStore: MockAppIDSettingsStore!
    var keychainService: MockKeychainService!
    var subject: DefaultKeychainRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appIDSettingsStore = MockAppIDSettingsStore()
        keychainService = MockKeychainService()
        subject = DefaultKeychainRepository(
            appIDService: AppIDService(
                appIDSettingsStore: appIDSettingsStore,
            ),
            keychainService: keychainService,
        )
    }

    override func tearDown() {
        super.tearDown()

        appIDSettingsStore = nil
        keychainService = nil
        subject = nil
    }

    // MARK: Tests - Server Communication Config

    /// `deleteServerCommunicationConfig(hostname:)` deletes the keychain item with the correct query.
    func test_deleteServerCommunicationConfig() async throws {
        let hostname = "example.com"
        let item = KeychainItem.serverCommunicationConfig(hostname: hostname)
        keychainService.deleteResult = .success(())
        let expectedQuery = await subject.keychainQueryValues(for: item)

        try await subject.deleteServerCommunicationConfig(hostname: hostname)

        XCTAssertEqual(keychainService.deleteQueries, [expectedQuery])
    }

    /// `getServerCommunicationConfig(hostname:)` returns the stored config.
    func test_getServerCommunicationConfig_success() async throws {
        let config = ServerCommunicationConfig(bootstrap: .direct)
        let configData = try JSONEncoder.defaultEncoder.encode(config)
        let configString = String(data: configData, encoding: .utf8)!
        keychainService.setSearchResultData(string: configString)

        let result = try await subject.getServerCommunicationConfig(hostname: "example.com")

        XCTAssertEqual(result, ServerCommunicationConfig(bootstrap: .direct))
    }

    /// `getServerCommunicationConfig(hostname:)` returns `nil` when the key is not found.
    func test_getServerCommunicationConfig_notFound_keyNotFound() async throws {
        keychainService.searchResult = .failure(
            KeychainServiceError.keyNotFound(KeychainItem.serverCommunicationConfig(hostname: "example.com")),
        )

        let result = try await subject.getServerCommunicationConfig(hostname: "example.com")

        XCTAssertNil(result)
    }

    /// `getServerCommunicationConfig(hostname:)` returns `nil` when the OS status indicates not found.
    func test_getServerCommunicationConfig_notFound_osStatus() async throws {
        keychainService.searchResult = .failure(KeychainServiceError.osStatusError(errSecItemNotFound))

        let result = try await subject.getServerCommunicationConfig(hostname: "example.com")

        XCTAssertNil(result)
    }

    /// `setServerCommunicationConfig(_:hostname:)` stores the config as JSON in the keychain.
    func test_setServerCommunicationConfig_withConfig() async throws {
        let item = KeychainItem.serverCommunicationConfig(hostname: "example.com")
        keychainService.accessControlResult = .success(
            SecAccessControlCreateWithFlags(
                nil,
                item.protection,
                item.accessControlFlags ?? [],
                nil,
            )!,
        )
        keychainService.updateResult = .success(())

        let config = ServerCommunicationConfig(bootstrap: .direct)
        try await subject.setServerCommunicationConfig(config, hostname: "example.com")

        let updateAttributes = try XCTUnwrap(keychainService.updateAttributes as? [CFString: Any])
        let valueData = try XCTUnwrap(updateAttributes[kSecValueData] as? Data)
        let decoded = try JSONDecoder.defaultDecoder.decode(ServerCommunicationConfig.self, from: valueData)
        XCTAssertEqual(decoded, ServerCommunicationConfig(bootstrap: .direct))
    }

    /// `setServerCommunicationConfig(_:hostname:)` deletes the keychain item when config is `nil`.
    func test_setServerCommunicationConfig_nilConfig() async throws {
        let hostname = "example.com"
        let item = KeychainItem.serverCommunicationConfig(hostname: hostname)
        keychainService.deleteResult = .success(())
        let expectedQuery = await subject.keychainQueryValues(for: item)

        try await subject.setServerCommunicationConfig(nil, hostname: hostname)

        XCTAssertEqual(keychainService.deleteQueries, [expectedQuery])
    }

    /// `unformattedKey` generates the expected unformatted key for server communication config.
    func test_unformattedKey_serverCommunicationConfig() {
        let item = KeychainItem.serverCommunicationConfig(hostname: "example.com")
        XCTAssertEqual(item.unformattedKey, "serverCommunicationConfig_example.com")
    }
}
