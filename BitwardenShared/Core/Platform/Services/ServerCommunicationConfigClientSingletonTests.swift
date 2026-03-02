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
                    cookieDomain: ".example.com",
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
                        cookieDomain: ".example.com",
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
                        cookieDomain: ".example.com",
                        cookieValue: nil,
                    ),
                ),
            ),
        )
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    // MARK: Private

    /// Creates a `CommunicationSettingsResponseModel` with an `ssoCookieVendor` bootstrap type.
    private func makeSSOCommunicationSettings(
        idpLoginUrl: String? = "https://idp.example.com",
        cookieName: String? = "sso_cookie",
        cookieDomain: String? = ".example.com",
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
