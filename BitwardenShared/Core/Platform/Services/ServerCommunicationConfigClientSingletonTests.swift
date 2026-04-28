import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - ServerCommunicationConfigClientSingletonTests

class ServerCommunicationConfigClientSingletonTests: BitwardenTestCase {
    // MARK: Properties

    var clientService: MockClientService!
    var configService: MockConfigService!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var sdkRepositoryFactory: MockSdkRepositoryFactory!
    var serverCommunicationConfigAPIService: MockServerCommunicationConfigAPIService!
    var serverCommunicationConfigClient: MockServerCommunicationConfigClient!
    var serverCommunicationConfigRepository: MockServerCommunicationConfigRepository!
    var stateService: MockStateService!
    var subject: DefaultServerCommunicationConfigClientSingleton!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        clientService = MockClientService()
        configService = MockConfigService()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        sdkRepositoryFactory = MockSdkRepositoryFactory()
        serverCommunicationConfigAPIService = MockServerCommunicationConfigAPIService()

        serverCommunicationConfigClient = MockServerCommunicationConfigClient()
        clientService.mockPlatform.serverCommunicationConfigResult = serverCommunicationConfigClient

        serverCommunicationConfigRepository = MockServerCommunicationConfigRepository()
        sdkRepositoryFactory.makeServerCommunicationConfigRepositoryReturnValue = serverCommunicationConfigRepository

        stateService = MockStateService()
        subject = DefaultServerCommunicationConfigClientSingleton(
            clientService: clientService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            sdkRepositoryFactory: sdkRepositoryFactory,
            serverCommunicationConfigAPIService: serverCommunicationConfigAPIService,
            serverCommunicationConfigStateService: stateService,
        )
    }

    override func tearDown() {
        super.tearDown()

        clientService = nil
        configService = nil
        environmentService = nil
        errorReporter = nil
        sdkRepositoryFactory = nil
        serverCommunicationConfigAPIService = nil
        serverCommunicationConfigClient = nil
        serverCommunicationConfigRepository = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `configPublisher` triggers `setCommunicationType` with the server config
    /// when no local config exists for the hostname.
    @MainActor
    func test_configPublisher_noLocalConfig_callsSetCommunicationType() async throws {
        let hostname = try XCTUnwrap(environmentService.webVaultURL.host)
        stateService.serverCommunicationConfigs[hostname] = nil

        configService.configSubject.send(makeMetaServerConfig())

        try await waitForAsync { self.serverCommunicationConfigClient.setCommunicationTypeCallsCount > 0 }

        XCTAssertEqual(serverCommunicationConfigClient.setCommunicationTypeReceivedHostname, hostname)
        XCTAssertEqual(
            serverCommunicationConfigClient.setCommunicationTypeReceivedConfig,
            ServerCommunicationConfig(bootstrap: .direct),
        )
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `configPublisher` triggers `setCommunicationType` with the server config
    /// when a local config exists for the hostname.
    @MainActor
    func test_configPublisher_withLocalConfig_callsSetCommunicationType() async throws {
        let hostname = try XCTUnwrap(environmentService.webVaultURL.host)
        stateService.serverCommunicationConfigs[hostname] = ServerCommunicationConfig(bootstrap: .direct)

        configService.configSubject.send(makeMetaServerConfig())

        try await waitForAsync { self.serverCommunicationConfigClient.setCommunicationTypeCallsCount > 0 }

        XCTAssertEqual(serverCommunicationConfigClient.setCommunicationTypeReceivedHostname, hostname)
        XCTAssertEqual(
            serverCommunicationConfigClient.setCommunicationTypeReceivedConfig,
            ServerCommunicationConfig(bootstrap: .direct),
        )
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `configPublisher` does nothing when the server config has no communication settings.
    @MainActor
    func test_configPublisher_noCommunicationSettings() async throws {
        configService.configSubject.send(makeMetaServerConfig(communication: nil))

        await Task.yield()

        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertEqual(clientService.platformCallCount, 0)
    }

    /// `configPublisher` does nothing when the environment's web vault URL has no host component.
    @MainActor
    func test_configPublisher_noHostname() async throws {
        environmentService.webVaultURL = URL(string: "data:text/plain")!

        configService.configSubject.send(makeMetaServerConfig())

        await Task.yield()

        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertEqual(clientService.platformCallCount, 0)
    }

    /// `configPublisher` triggers `setCommunicationType` when a local config exists
    /// for the hostname, logging any errors thrown by the SDK client.
    @MainActor
    func test_configPublisher_withLocalConfig_logsSDKClientError() async throws {
        let hostname = try XCTUnwrap(environmentService.webVaultURL.host)
        stateService.serverCommunicationConfigs[hostname] = ServerCommunicationConfig(bootstrap: .direct)
        clientService.platformError = BitwardenTestError.example

        configService.configSubject.send(makeMetaServerConfig())

        try await waitForAsync { !self.errorReporter.errors.isEmpty }

        XCTAssertEqual((errorReporter.errors as? [BitwardenTestError])?.first, .example)
    }

    /// `configPublisher` logs an error when the state service throws.
    @MainActor
    func test_configPublisher_stateServiceError_logsError() async throws {
        stateService.getServerCommunicationConfigError = BitwardenTestError.example

        configService.configSubject.send(makeMetaServerConfig())

        try await waitForAsync { !self.errorReporter.errors.isEmpty }

        XCTAssertEqual((errorReporter.errors as? [BitwardenTestError])?.first, .example)
    }

    /// `configPublisher` triggers `setCommunicationType` preserving the cookie value from the
    /// local config when both the server config and local config are `ssoCookieVendor`.
    @MainActor
    func test_configPublisher_bothSSO_preservesCookieValue() async throws {
        let hostname = try XCTUnwrap(environmentService.webVaultURL.host)
        let cookieValue = [AcquiredCookie(name: "cookie", value: "stored_value")]
        stateService.serverCommunicationConfigs[hostname] = ServerCommunicationConfig(
            bootstrap: .ssoCookieVendor(
                SsoCookieVendorConfig(
                    idpLoginUrl: "https://idp.example.com",
                    cookieName: "sso_cookie",
                    cookieDomain: "example.com",
                    vaultUrl: "https://example.com",
                    cookieValue: cookieValue,
                ),
            ),
        )

        configService.configSubject.send(makeMetaServerConfig(communication: makeSSOCommunicationSettings()))

        try await waitForAsync { self.serverCommunicationConfigClient.setCommunicationTypeCallsCount > 0 }

        XCTAssertEqual(serverCommunicationConfigClient.setCommunicationTypeReceivedHostname, hostname)
        XCTAssertEqual(
            serverCommunicationConfigClient.setCommunicationTypeReceivedConfig,
            ServerCommunicationConfig(
                bootstrap: .ssoCookieVendor(
                    SsoCookieVendorConfig(
                        idpLoginUrl: "https://idp.example.com",
                        cookieName: "sso_cookie",
                        cookieDomain: "example.com",
                        vaultUrl: nil,
                        cookieValue: [AcquiredCookie(name: "cookie", value: "stored_value")],
                    ),
                ),
            ),
        )
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `configPublisher` triggers `setCommunicationType` with the server config as-is when the
    /// server config is `ssoCookieVendor` but the local config is `direct`.
    @MainActor
    func test_configPublisher_serverSSO_localDirect_doesNotPreserveCookieValue() async throws {
        let hostname = try XCTUnwrap(environmentService.webVaultURL.host)
        stateService.serverCommunicationConfigs[hostname] = ServerCommunicationConfig(bootstrap: .direct)

        configService.configSubject.send(makeMetaServerConfig(communication: makeSSOCommunicationSettings()))

        try await waitForAsync { self.serverCommunicationConfigClient.setCommunicationTypeCallsCount > 0 }

        XCTAssertEqual(serverCommunicationConfigClient.setCommunicationTypeReceivedHostname, hostname)
        XCTAssertEqual(
            serverCommunicationConfigClient.setCommunicationTypeReceivedConfig,
            ServerCommunicationConfig(
                bootstrap: .ssoCookieVendor(
                    SsoCookieVendorConfig(
                        idpLoginUrl: "https://idp.example.com",
                        cookieName: "sso_cookie",
                        cookieDomain: "example.com",
                        vaultUrl: nil,
                        cookieValue: nil,
                    ),
                ),
            ),
        )
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    // MARK: resolveHostname tests

    /// `resolveHostname(hostname:)` returns the exact hostname when the state service has a config for it.
    @MainActor
    func test_resolveHostname_exactMatch_returnsHostname() async throws {
        let hostname = "example.com"
        stateService.serverCommunicationConfigs[hostname] = ServerCommunicationConfig(bootstrap: .direct)

        let result = await subject.resolveHostname(hostname: hostname)

        XCTAssertEqual(result, hostname)
    }

    /// `resolveHostname(hostname:)` strips subdomains until it finds a stored config key.
    @MainActor
    func test_resolveHostname_subdomain_fallsBackToParentDomain() async throws {
        stateService.serverCommunicationConfigs["example.com"] = ServerCommunicationConfig(bootstrap: .direct)

        let result = await subject.resolveHostname(hostname: "api.example.com")

        XCTAssertEqual(result, "example.com")
    }

    /// `resolveHostname(hostname:)` returns the original hostname when no config is found at any level.
    @MainActor
    func test_resolveHostname_noMatch_returnsOriginalHostname() async throws {
        let result = await subject.resolveHostname(hostname: "api.example.com")

        XCTAssertEqual(result, "api.example.com")
    }

    /// `resolveHostname(hostname:)` logs an error when the state service throws and returns the original hostname.
    @MainActor
    func test_resolveHostname_stateServiceError_logsErrorAndReturnsHostname() async throws {
        stateService.getServerCommunicationConfigError = BitwardenTestError.example

        let result = await subject.resolveHostname(hostname: "api.example.com")

        XCTAssertEqual(result, "api.example.com")
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    // MARK: configPublisher tests

    /// `configPublisher` uses the `cookieDomain` from the bootstrap config as the hostname key when present.
    @MainActor
    func test_configPublisher_ssoCookieVendor_usesCookieDomainAsHostname() async throws {
        let cookieDomain = "example.com"
        let hostname = "example.com"
        sdkRepositoryFactory.makeServerCommunicationConfigRepositoryReturnValue =
            SdkServerCommunicationConfigRepository(serverCommunicationConfigStateService: stateService)

        configService.configSubject.send(
            makeMetaServerConfig(communication: makeSSOCommunicationSettings(cookieDomain: cookieDomain)),
        )

        try await waitForAsync { self.serverCommunicationConfigClient.setCommunicationTypeCallsCount > 0 }

        XCTAssertEqual(serverCommunicationConfigClient.setCommunicationTypeReceivedHostname, hostname)
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `configPublisher` falls back to the environment's web vault URL host when `cookieDomain` is `nil`.
    @MainActor
    func test_configPublisher_ssoCookieVendor_nilCookieDomain_fallsBackToWebVaultHost() async throws {
        let expectedHostname = try XCTUnwrap(environmentService.webVaultURL.host)
        sdkRepositoryFactory.makeServerCommunicationConfigRepositoryReturnValue =
            SdkServerCommunicationConfigRepository(serverCommunicationConfigStateService: stateService)

        configService.configSubject.send(
            makeMetaServerConfig(communication: makeSSOCommunicationSettings(cookieDomain: nil)),
        )

        try await waitForAsync { self.serverCommunicationConfigClient.setCommunicationTypeCallsCount > 0 }

        XCTAssertEqual(serverCommunicationConfigClient.setCommunicationTypeReceivedHostname, expectedHostname)
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    // MARK: Private

    /// Creates a `CommunicationSettingsResponseModel` with an `ssoCookieVendor` bootstrap type.
    private func makeSSOCommunicationSettings(
        idpLoginUrl: String? = "https://idp.example.com",
        cookieName: String? = "sso_cookie",
        cookieDomain: String? = "example.com",
    ) -> CommunicationSettingsResponseModel {
        CommunicationSettingsResponseModel(
            bootstrap: CommunicationBootstrapSettingsResponseModel(
                type: "ssoCookieVendor",
                idpLoginUrl: idpLoginUrl,
                cookieName: cookieName,
                cookieDomain: cookieDomain,
            ),
        )
    }

    /// Creates a `MetaServerConfig` for use in tests.
    /// - Parameter communication: The communication settings to include in the server config.
    ///   Defaults to a `direct` bootstrap type. Pass `nil` to omit communication settings.
    private func makeMetaServerConfig(
        communication: CommunicationSettingsResponseModel? = CommunicationSettingsResponseModel(
            bootstrap: CommunicationBootstrapSettingsResponseModel(
                type: "direct",
                idpLoginUrl: nil,
                cookieName: nil,
                cookieDomain: nil,
            ),
        ),
    ) -> MetaServerConfig {
        MetaServerConfig(
            isPreAuth: false,
            userId: nil,
            serverConfig: ServerConfig(
                date: Date(),
                responseModel: ConfigResponseModel(
                    communication: communication,
                    environment: nil,
                    featureStates: [:],
                    gitHash: "abc123",
                    server: nil,
                    version: "2024.1.0",
                ),
            ),
        )
    }
}
