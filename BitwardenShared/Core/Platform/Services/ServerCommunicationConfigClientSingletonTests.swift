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
        stateService = MockStateService()
        subject = DefaultServerCommunicationConfigClientSingleton(
            clientService: clientService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            sdkRepositoryFactory: sdkRepositoryFactory,
            serverCommunicationConfigAPIService: serverCommunicationConfigAPIService,
            stateService: stateService,
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
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `configPublisher` triggers `setCommunicationType` with the server config
    /// when no local config exists for the hostname.
    @MainActor
    func test_configPublisher_noLocalConfig_callsSetCommunicationType() async throws {
        let hostname = try XCTUnwrap(environmentService.webVaultURL.host)
        let mockSdkClient = MockServerCommunicationConfigClient()
        clientService.mockPlatform.serverCommunicationConfigResult = mockSdkClient
        sdkRepositoryFactory.makeServerCommunicationConfigRepositoryReturnValue =
            SdkServerCommunicationConfigRepository(stateService: stateService)

        configService.configSubject.send(makeMetaServerConfig())

        try await waitForAsync { mockSdkClient.setCommunicationTypeCallsCount == 1 }

        XCTAssertEqual(mockSdkClient.setCommunicationTypeReceivedHostname, hostname)
        XCTAssertEqual(mockSdkClient.setCommunicationTypeReceivedConfig, ServerCommunicationConfig(bootstrap: .direct))
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `configPublisher` triggers `setCommunicationType` with the server config
    /// when a local config exists for the hostname.
    @MainActor
    func test_configPublisher_withLocalConfig_callsSetCommunicationType() async throws {
        let hostname = try XCTUnwrap(environmentService.webVaultURL.host)
        stateService.serverCommunicationConfigs[hostname] = ServerCommunicationConfig(bootstrap: .direct)
        let mockSdkClient = MockServerCommunicationConfigClient()
        clientService.mockPlatform.serverCommunicationConfigResult = mockSdkClient
        sdkRepositoryFactory.makeServerCommunicationConfigRepositoryReturnValue =
            SdkServerCommunicationConfigRepository(stateService: stateService)

        configService.configSubject.send(makeMetaServerConfig())

        try await waitForAsync { mockSdkClient.setCommunicationTypeCallsCount == 1 }

        XCTAssertEqual(mockSdkClient.setCommunicationTypeReceivedHostname, hostname)
        XCTAssertEqual(mockSdkClient.setCommunicationTypeReceivedConfig, ServerCommunicationConfig(bootstrap: .direct))
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `configPublisher` does nothing when the server config has no communication settings.
    @MainActor
    func test_configPublisher_noCommunicationSettings() async throws {
        configService.configSubject.send(makeMetaServerConfig(communication: nil))

        await Task.yield()
        await Task.yield()
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
        await Task.yield()
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

        XCTAssertEqual(clientService.platformCallCount, 1)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `configPublisher` logs an error when the state service throws.
    @MainActor
    func test_configPublisher_stateServiceError_logsError() async throws {
        stateService.getServerCommunicationConfigError = BitwardenTestError.example

        configService.configSubject.send(makeMetaServerConfig())

        try await waitForAsync { !self.errorReporter.errors.isEmpty }

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    // MARK: Private

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
        )
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
