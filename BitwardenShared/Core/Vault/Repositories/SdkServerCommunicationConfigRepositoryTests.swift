import BitwardenKitMocks
import BitwardenSdk

import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SdkServerCommunicationConfigRepositoryTests

class SdkServerCommunicationConfigRepositoryTests: BitwardenTestCase {
    // MARK: Properties

    var serverCommunicationConfigStateService: MockServerCommunicationConfigStateService!
    var subject: SdkServerCommunicationConfigRepository!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        serverCommunicationConfigStateService = MockServerCommunicationConfigStateService()
        subject = SdkServerCommunicationConfigRepository(
            serverCommunicationConfigStateService: serverCommunicationConfigStateService,
        )
    }

    override func tearDown() {
        super.tearDown()

        serverCommunicationConfigStateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `get(hostname:)` returns the config stored for the given hostname.
    func test_get_returnsStoredConfig() async throws {
        let hostname = "example.com"
        serverCommunicationConfigStateService.getServerCommunicationConfigReturnValue = ServerCommunicationConfig(
            bootstrap: .direct,
        )

        let result = try await subject.get(hostname: hostname)

        XCTAssertEqual(result, ServerCommunicationConfig(bootstrap: .direct))
    }

    /// `get(hostname:)` returns `nil` when no config exists for the hostname.
    func test_get_returnsNilWhenNoConfig() async throws {
        let result = try await subject.get(hostname: "example.com")

        XCTAssertNil(result)
    }

    /// `get(hostname:)` throws when the state service throws.
    func test_get_throwsError() async {
        serverCommunicationConfigStateService.getServerCommunicationConfigThrowableError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.get(hostname: "example.com")
        }
    }

    /// `save(hostname:config:)` saves the config directly when no local config exists.
    func test_save_noExistingConfig_savesConfigDirectly() async throws {
        let hostname = "example.com"
        let config = ServerCommunicationConfig(bootstrap: .direct)

        try await subject.save(hostname: hostname, config: config)

        let saved = serverCommunicationConfigStateService.setServerCommunicationConfigReceivedArguments?.config

        XCTAssertEqual(saved, ServerCommunicationConfig(bootstrap: .direct))
    }

    /// `save(hostname:config:)` merges the cookie value from the incoming config when a local
    /// config already exists, preserving the local config's identity fields.
    func test_save_existingConfig_mergesCookieValue() async throws {
        let hostname = "example.com"
        let localConfig = ServerCommunicationConfig(
            bootstrap: .ssoCookieVendor(
                SsoCookieVendorConfig(
                    idpLoginUrl: "https://idp.example.com",
                    cookieName: "bwauth",
                    cookieDomain: "example.com",
                    vaultUrl: "https://example.com",
                    cookieValue: nil,
                ),
            ),
        )
        let incomingConfig = ServerCommunicationConfig(
            bootstrap: .ssoCookieVendor(
                SsoCookieVendorConfig(
                    idpLoginUrl: "https://idp.example.com",
                    cookieName: "bwauth",
                    cookieDomain: "example.com",
                    vaultUrl: "https://example.com",
                    cookieValue: [AcquiredCookie(name: "session", value: "token123")],
                ),
            ),
        )
        serverCommunicationConfigStateService.getServerCommunicationConfigReturnValue = localConfig

        try await subject.save(hostname: hostname, config: incomingConfig)

        let saved = serverCommunicationConfigStateService.setServerCommunicationConfigReceivedArguments?.config
        guard case let .ssoCookieVendor(savedSsoConfig) = saved?.bootstrap else {
            XCTFail("Expected .ssoCookieVendor bootstrap after save")
            return
        }
        XCTAssertEqual(savedSsoConfig.idpLoginUrl, "https://idp.example.com")
        XCTAssertEqual(savedSsoConfig.cookieName, "bwauth")
        XCTAssertEqual(savedSsoConfig.cookieDomain, "example.com")
        XCTAssertEqual(savedSsoConfig.cookieValue?.first?.name, "session")
        XCTAssertEqual(savedSsoConfig.cookieValue?.first?.value, "token123")
        XCTAssertEqual(savedSsoConfig.vaultUrl, "https://example.com")
    }

    /// `save(hostname:config:)` throws when `getServerCommunicationConfig` throws.
    func test_save_throwsOnGetError() async {
        serverCommunicationConfigStateService.getServerCommunicationConfigThrowableError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await self.subject.save(
                hostname: "example.com",
                config: ServerCommunicationConfig(bootstrap: .direct),
            )
        }
    }

    /// `save(hostname:config:)` throws when `setServerCommunicationConfig` throws.
    func test_save_throwsOnSetError() async {
        serverCommunicationConfigStateService.setServerCommunicationConfigThrowableError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await self.subject.save(
                hostname: "example.com",
                config: ServerCommunicationConfig(bootstrap: .direct),
            )
        }
    }
}
