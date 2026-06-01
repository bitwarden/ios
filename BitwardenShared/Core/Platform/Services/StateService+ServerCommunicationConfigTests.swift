// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - StateServiceServerCommunicationConfigTests

class StateServiceServerCommunicationConfigTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var dataStore: DataStore!
    var errorReporter: MockErrorReporter!
    var keychainRepository: MockKeychainRepository!
    var userSessionKeychainRepository: MockUserSessionKeychainRepository!
    var subject: DefaultStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        dataStore = DataStore(errorReporter: MockErrorReporter(), storeType: .memory)
        errorReporter = MockErrorReporter()
        keychainRepository = MockKeychainRepository()
        userSessionKeychainRepository = MockUserSessionKeychainRepository()

        subject = DefaultStateService(
            appSettingsStore: appSettingsStore,
            dataStore: dataStore,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository,
            timeProvider: CurrentTime(),
            userSessionKeychainRepository: userSessionKeychainRepository,
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        dataStore = nil
        errorReporter = nil
        keychainRepository = nil
        subject = nil
        userSessionKeychainRepository = nil
    }

    // MARK: Tests - Server Communication Config

    /// `clearServerCommunicationCookieValue(hostname:)` clears the cookie value from a stored
    /// `ssoCookieVendor` config while preserving the other fields.
    func test_clearServerCommunicationCookieValue_ssoCookieVendor() async throws {
        let hostname = "example.com"
        let config = ServerCommunicationConfig(
            bootstrap: .ssoCookieVendor(
                SsoCookieVendorConfig(
                    idpLoginUrl: "https://idp.example.com",
                    cookieName: "bwauth",
                    cookieDomain: "example.com",
                    vaultUrl: "https://example.com",
                    cookieValue: [AcquiredCookie(name: "session", value: "token")],
                ),
            ),
        )
        keychainRepository.getServerCommunicationConfigReturnValue = config

        try await subject.clearServerCommunicationCookieValue(hostname: hostname)

        let savedConfig = keychainRepository.setServerCommunicationConfigReceivedArguments?.config
        guard case let .ssoCookieVendor(savedSsoConfig) = savedConfig?.bootstrap else {
            XCTFail("Expected .ssoCookieVendor bootstrap after clearing")
            return
        }
        XCTAssertEqual(savedSsoConfig.idpLoginUrl, "https://idp.example.com")
        XCTAssertEqual(savedSsoConfig.cookieName, "bwauth")
        XCTAssertEqual(savedSsoConfig.cookieDomain, "example.com")
        XCTAssertNil(savedSsoConfig.cookieValue)
        XCTAssertEqual(savedSsoConfig.vaultUrl, "https://example.com")
        XCTAssertEqual(keychainRepository.setServerCommunicationConfigReceivedArguments?.hostname, hostname)
    }

    /// `clearServerCommunicationCookieValue(hostname:)` does nothing when no config exists.
    func test_clearServerCommunicationCookieValue_noConfig() async throws {
        keychainRepository.getServerCommunicationConfigReturnValue = nil

        try await subject.clearServerCommunicationCookieValue(hostname: "example.com")

        XCTAssertNil(keychainRepository.setServerCommunicationConfigReceivedArguments?.config)
    }

    /// `clearServerCommunicationCookieValue(hostname:)` does nothing when the stored config
    /// uses the `.direct` bootstrap (no SSO cookie to clear).
    func test_clearServerCommunicationCookieValue_directBootstrap() async throws {
        keychainRepository.getServerCommunicationConfigReturnValue = ServerCommunicationConfig(bootstrap: .direct)

        try await subject.clearServerCommunicationCookieValue(hostname: "example.com")

        XCTAssertNil(keychainRepository.setServerCommunicationConfigReceivedArguments?.config)
    }

    /// `getServerCommunicationConfig(hostname:)` returns the stored config from the keychain.
    func test_getServerCommunicationConfig_success() async throws {
        let config = ServerCommunicationConfig(bootstrap: .direct)
        keychainRepository.getServerCommunicationConfigReturnValue = config

        let result = try await subject.getServerCommunicationConfig(hostname: "example.com")

        XCTAssertEqual(result, ServerCommunicationConfig(bootstrap: .direct))
    }

    /// `getServerCommunicationConfig(hostname:)` returns `nil` when the keychain has no entry.
    func test_getServerCommunicationConfig_notFound() async throws {
        keychainRepository.getServerCommunicationConfigReturnValue = nil

        let result = try await subject.getServerCommunicationConfig(hostname: "example.com")

        XCTAssertNil(result)
    }

    /// `setServerCommunicationConfig(_:hostname:)` delegates to the keychain repository.
    func test_setServerCommunicationConfig() async throws {
        let hostname = "example.com"
        let config = ServerCommunicationConfig(bootstrap: .direct)

        try await subject.setServerCommunicationConfig(config, hostname: hostname)

        XCTAssertEqual(keychainRepository.setServerCommunicationConfigReceivedArguments?.hostname, hostname)
        let saved = keychainRepository.setServerCommunicationConfigReceivedArguments?.config
        guard case .direct = saved?.bootstrap else {
            XCTFail("Expected .direct bootstrap in saved config")
            return
        }
    }
}
