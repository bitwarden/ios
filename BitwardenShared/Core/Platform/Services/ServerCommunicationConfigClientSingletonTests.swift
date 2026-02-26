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

    /// `updateSDKCommunicationType(_:)` calls `setCommunicationType` with the server config
    /// when no local config exists for the hostname.
    func test_updateSDKCommunicationType_noLocalConfig_callsSetCommunicationType() async throws {
        let hostname = try XCTUnwrap(environmentService.webVaultURL.host)
        let mockSdkClient = MockServerCommunicationConfigClient()
        clientService.mockPlatform.serverCommunicationConfigResult = mockSdkClient
        sdkRepositoryFactory.makeServerCommunicationConfigRepositoryReturnValue =
            SdkServerCommunicationConfigRepository(stateService: stateService)

        let config = ServerConfig(
            date: Date(),
            responseModel: ConfigResponseModel(
                communication: CommunicationSettingsResponseModel(
                    bootstrap: CommunicationBootstrapSettingsResponseModel(
                        type: "direct",
                        idpLoginUrl: nil,
                        cookieName: nil,
                        cookieDomain: nil,
                    ),
                ),
                environment: nil,
                featureStates: [:],
                gitHash: "abc123",
                server: nil,
                version: "2024.1.0",
            ),
        )

        await subject.updateSDKCommunicationType(config)

        XCTAssertEqual(mockSdkClient.setCommunicationTypeCallsCount, 1)
        XCTAssertEqual(mockSdkClient.setCommunicationTypeReceivedHostname, hostname)
        XCTAssertEqual(mockSdkClient.setCommunicationTypeReceivedConfig, ServerCommunicationConfig(bootstrap: .direct))
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `updateSDKCommunicationType(_:)` calls `setCommunicationType` with the server config
    /// when a local config exists for the hostname.
    func test_updateSDKCommunicationType_withLocalConfig_callsSetCommunicationType() async throws {
        let hostname = try XCTUnwrap(environmentService.webVaultURL.host)
        stateService.serverCommunicationConfigs[hostname] = ServerCommunicationConfig(bootstrap: .direct)
        let mockSdkClient = MockServerCommunicationConfigClient()
        clientService.mockPlatform.serverCommunicationConfigResult = mockSdkClient
        sdkRepositoryFactory.makeServerCommunicationConfigRepositoryReturnValue =
            SdkServerCommunicationConfigRepository(stateService: stateService)

        let config = ServerConfig(
            date: Date(),
            responseModel: ConfigResponseModel(
                communication: CommunicationSettingsResponseModel(
                    bootstrap: CommunicationBootstrapSettingsResponseModel(
                        type: "direct",
                        idpLoginUrl: nil,
                        cookieName: nil,
                        cookieDomain: nil,
                    ),
                ),
                environment: nil,
                featureStates: [:],
                gitHash: "abc123",
                server: nil,
                version: "2024.1.0",
            ),
        )

        await subject.updateSDKCommunicationType(config)

        XCTAssertEqual(mockSdkClient.setCommunicationTypeCallsCount, 1)
        XCTAssertEqual(mockSdkClient.setCommunicationTypeReceivedHostname, hostname)
        XCTAssertEqual(mockSdkClient.setCommunicationTypeReceivedConfig, ServerCommunicationConfig(bootstrap: .direct))
        XCTAssertTrue(errorReporter.errors.isEmpty)
    }

    /// `updateSDKCommunicationType(_:)` returns early and does nothing when the server config
    /// has no communication settings.
    func test_updateSDKCommunicationType_noCommunicationSettings() async {
        let config = ServerConfig(
            date: Date(),
            responseModel: ConfigResponseModel(
                communication: nil,
                environment: nil,
                featureStates: [:],
                gitHash: "abc123",
                server: nil,
                version: "2024.1.0",
            ),
        )

        await subject.updateSDKCommunicationType(config)

        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertEqual(clientService.platformCallCount, 0)
    }

    /// `updateSDKCommunicationType(_:)` returns early and does nothing when the environment's
    /// web vault URL has no host component.
    func test_updateSDKCommunicationType_noHostname() async {
        environmentService.webVaultURL = URL(string: "data:text/plain")!
        let config = ServerConfig(
            date: Date(),
            responseModel: ConfigResponseModel(
                communication: CommunicationSettingsResponseModel(
                    bootstrap: CommunicationBootstrapSettingsResponseModel(
                        type: "direct",
                        idpLoginUrl: nil,
                        cookieName: nil,
                        cookieDomain: nil,
                    ),
                ),
                environment: nil,
                featureStates: [:],
                gitHash: "abc123",
                server: nil,
                version: "2024.1.0",
            ),
        )

        await subject.updateSDKCommunicationType(config)

        XCTAssertTrue(errorReporter.errors.isEmpty)
        XCTAssertEqual(clientService.platformCallCount, 0)
    }

    /// `updateSDKCommunicationType(_:)` calls `setCommunicationType` when a local config exists
    /// for the hostname, logging any errors thrown by the SDK client.
    func test_updateSDKCommunicationType_withLocalConfig_logsSDKClientError() async throws {
        let hostname = try XCTUnwrap(environmentService.webVaultURL.host)
        stateService.serverCommunicationConfigs[hostname] = ServerCommunicationConfig(bootstrap: .direct)
        clientService.platformError = BitwardenTestError.example

        let config = ServerConfig(
            date: Date(),
            responseModel: ConfigResponseModel(
                communication: CommunicationSettingsResponseModel(
                    bootstrap: CommunicationBootstrapSettingsResponseModel(
                        type: "direct",
                        idpLoginUrl: nil,
                        cookieName: nil,
                        cookieDomain: nil,
                    ),
                ),
                environment: nil,
                featureStates: [:],
                gitHash: "abc123",
                server: nil,
                version: "2024.1.0",
            ),
        )

        await subject.updateSDKCommunicationType(config)

        XCTAssertEqual(clientService.platformCallCount, 1)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `updateSDKCommunicationType(_:)` logs an error when the state service throws.
    func test_updateSDKCommunicationType_stateServiceError_logsError() async {
        stateService.getServerCommunicationConfigError = BitwardenTestError.example
        let config = ServerConfig(
            date: Date(),
            responseModel: ConfigResponseModel(
                communication: CommunicationSettingsResponseModel(
                    bootstrap: CommunicationBootstrapSettingsResponseModel(
                        type: "direct",
                        idpLoginUrl: nil,
                        cookieName: nil,
                        cookieDomain: nil,
                    ),
                ),
                environment: nil,
                featureStates: [:],
                gitHash: "abc123",
                server: nil,
                version: "2024.1.0",
            ),
        )

        await subject.updateSDKCommunicationType(config)

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }
}
