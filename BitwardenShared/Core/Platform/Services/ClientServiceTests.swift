import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import XCTest

@testable import BitwardenShared

// swiftlint:disable file_length

final class ClientServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    var clientBuilder: MockClientBuilder!
    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var sdkRepositoryFactory: MockSdkRepositoryFactory!
    var stateService: MockStateService!
    var subject: DefaultClientService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        clientBuilder = MockClientBuilder()
        configService = MockConfigService()
        errorReporter = MockErrorReporter()
        sdkRepositoryFactory = MockSdkRepositoryFactory()
        sdkRepositoryFactory.makeCipherRepositoryReturnValue = MockSdkCipherRepository()
        stateService = MockStateService()
        subject = DefaultClientService(
            clientBuilder: clientBuilder,
            configService: configService,
            errorReporter: errorReporter,
            sdkRepositoryFactory: sdkRepositoryFactory,
            stateService: stateService
        )
        vaultTimeoutService = MockVaultTimeoutService()
    }

    override func tearDown() {
        super.tearDown()

        clientBuilder = nil
        configService = nil
        errorReporter = nil
        sdkRepositoryFactory = nil
        stateService = nil
        subject = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `auth(for:)` returns a new `AuthClientProtocol` for every user.
    func test_auth() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let auth = try await subject.auth()
        XCTAssertIdentical(auth, clientBuilder.clients.first?.authClient)

        let user2Auth = try await subject.auth(for: "2")
        XCTAssertNotIdentical(auth, user2Auth)
    }

    /// `auth(for:)` logs an error if there's no accounts and the `isPreAuth` flag isn't set.
    func test_auth_noAccountsNotPreAuth() async throws {
        let auth1 = try await subject.auth()
        let auth2 = try await subject.auth()
        XCTAssertNotIdentical(auth1, auth2)

        XCTAssertEqual(errorReporter.errors.count, 2)
        XCTAssertEqual((errorReporter.errors[0] as NSError).domain, "General Error: Missing isPreAuth")
        XCTAssertEqual((errorReporter.errors[1] as NSError).domain, "General Error: Missing isPreAuth")
    }

    /// `client(for:)` called concurrently doesn't crash.
    func test_client_calledConcurrently() async throws {
        // Calling `client(for:)` concurrently shouldn't throw an exception due to simultaneous
        // access to shared state. Since it's a race condition, running it repeatedly should expose
        // the failure if it's going to fail.
        for _ in 0 ..< 5 {
            async let concurrentTask1 = subject.auth(for: "1")
            async let concurrentTask2 = subject.auth(for: "1")

            _ = try await (concurrentTask1, concurrentTask2)
        }
    }

    /// Tests that `client(for:)` creates a new client if there is no active user/if there are no users.
    /// Also tests that `client(for:)` returns a user's existing client.
    /// Also tests that a `client(for:)` creates a new client if a user doesn't  have one.
    func test_client_multiple_users() async throws {
        // No active user.
        let noActiveUserAuth = try await subject.auth()
        let auth = clientBuilder.clients.first?.authClient
        XCTAssertIdentical(noActiveUserAuth, auth)

        // Creates new client for user that doesn't have one.
        let userAuth = try await subject.auth(for: "1")
        XCTAssertNotIdentical(noActiveUserAuth, userAuth)

        // Creates a new client for a different user.
        let user2Auth = try await subject.auth(for: "2")
        XCTAssertNotIdentical(noActiveUserAuth, user2Auth)
        XCTAssertNotIdentical(userAuth, user2Auth)

        // Returns a user's existing client.
        let userExistingAuthClient = try await subject.auth(for: "1")
        XCTAssertIdentical(userAuth, userExistingAuthClient)
    }

    /// `client(for:)` loads flags into the SDK.
    @MainActor
    func test_client_loadFlags() async throws {
        configService.featureFlagsBool[.cipherKeyEncryption] = true
        configService.configMocker.withResult(ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0"
            )
        ))

        _ = try await subject.auth(for: "1")

        let client = try XCTUnwrap(clientBuilder.clients.first)
        XCTAssertEqual(
            client.platformClient.featureFlags,
            ["enableCipherKeyEncryption": true]
        )
    }

    /// `client(for:)` loads `enableCipherKeyEncryption` flag as `false` into the SDK
    /// when the server version is old.
    @MainActor
    func test_client_loadFlagsEnableCipherKeyEncryptionFalseBecauseOfServerVersion() async throws {
        configService.featureFlagsBool[.cipherKeyEncryption] = true
        configService.configMocker.withResult(ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238191",
                server: nil,
                version: "2024.1.0"
            )
        ))

        _ = try await subject.auth(for: "1")

        let client = try XCTUnwrap(clientBuilder.clients.first)
        XCTAssertEqual(
            client.platformClient.featureFlags,
            ["enableCipherKeyEncryption": false]
        )
    }

    /// `client(for:)` loads `enableCipherKeyEncryption` flag as `false` into the SDK
    /// when the server version is old.
    @MainActor
    func test_client_loadFlagsEnableCipherKeyEncryptionFalseBecauseOfFeatureFlag() async throws {
        configService.featureFlagsBool[.cipherKeyEncryption] = false
        configService.configMocker.withResult(ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238191",
                server: nil,
                version: "2024.4.0"
            )
        ))

        _ = try await subject.auth(for: "1")

        let client = try XCTUnwrap(clientBuilder.clients.first)
        XCTAssertEqual(
            client.platformClient.featureFlags,
            ["enableCipherKeyEncryption": false]
        )
    }

    /// `client(for:)` loading flags throws.
    @MainActor
    func test_client_loadFlagsThrows() async throws {
        configService.configMocker.withResult(ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238191",
                server: nil,
                version: "2024.6.0"
            )
        ))
        clientBuilder.setupClientOnCreation = { client in
            client.platformClient.loadFlagsError = BitwardenTestError.example
        }

        _ = try await subject.auth(for: "1")

        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `client(for:)` does not load flags when config is `nil`.
    @MainActor
    func test_client_doesNotloadFlags() async throws {
        configService.configMocker.withResult(nil)

        _ = try await subject.auth(for: "1")

        let client = try XCTUnwrap(clientBuilder.clients.first)
        XCTAssertEqual(
            client.platformClient.featureFlags,
            [:]
        )
    }

    /// `client(for:)` registers the SDK cipher repository.
    func test_client_registersCipherRepository() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let auth = try await subject.auth()
        let client = try XCTUnwrap(clientBuilder.clients.first)
        XCTAssertIdentical(auth, client.authClient)
        XCTAssertTrue(sdkRepositoryFactory.makeCipherRepositoryCalled)
        XCTAssertNotNil(client.platformClient.stateMock.registerCipherRepositoryReceivedStore)
    }

    /// `configPublisher` loads flags into the SDK.
    @MainActor
    func test_configPublisher_loadFlags() async throws {
        configService.featureFlagsBool[.cipherKeyEncryption] = true
        configService.configSubject.send(
            MetaServerConfig(
                isPreAuth: false,
                userId: "1",
                serverConfig: ServerConfig(
                    date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
                    responseModel: ConfigResponseModel(
                        environment: nil,
                        featureStates: ["cipher-key-encryption": .bool(true)],
                        gitHash: "75238191",
                        server: nil,
                        version: "2024.4.0"
                    )
                )
            )
        )

        try await waitForAsync {
            guard !self.clientBuilder.clients.isEmpty else {
                return false
            }
            let client = try? XCTUnwrap(self.clientBuilder.clients.first)
            return client?.platformClient.featureFlags == ["enableCipherKeyEncryption": true]
        }
    }

    /// `configPublisher` loads flags into the SDK on a already created client taking into account
    /// changing the cipher-key-encryption feature flag.
    @MainActor
    func test_configPublisher_loadFlagsOverride() async throws { // swiftlint:disable:this function_body_length
        configService.configMocker.withResult(ServerConfig(
            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
            responseModel: ConfigResponseModel(
                environment: nil,
                featureStates: [:],
                gitHash: "75238199",
                server: nil,
                version: "2024.1.0"
            )
        ))

        _ = try await subject.auth(for: "1")
        let client = try XCTUnwrap(clientBuilder.clients.first)
        XCTAssertEqual(
            client.platformClient.featureFlags,
            ["enableCipherKeyEncryption": false]
        )

        configService.configSubject.send(
            MetaServerConfig(
                isPreAuth: false,
                userId: "1",
                serverConfig: ServerConfig(
                    date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
                    responseModel: ConfigResponseModel(
                        environment: nil,
                        featureStates: [:],
                        gitHash: "75238191",
                        server: nil,
                        version: "2024.4.0"
                    )
                )
            )
        )

        try await waitForAsync {
            let client = try? XCTUnwrap(self.clientBuilder.clients.first)
            return client?.platformClient.featureFlags == ["enableCipherKeyEncryption": false]
        }
        XCTAssertEqual(clientBuilder.clients.count, 1)

        configService.featureFlagsBool[.cipherKeyEncryption] = true
        configService.configSubject.send(
            MetaServerConfig(
                isPreAuth: false,
                userId: "1",
                serverConfig: ServerConfig(
                    date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
                    responseModel: ConfigResponseModel(
                        environment: nil,
                        featureStates: ["cipher-key-encryption": .bool(true)],
                        gitHash: "75238191",
                        server: nil,
                        version: "2024.4.0"
                    )
                )
            )
        )

        try await waitForAsync {
            let client = try? XCTUnwrap(self.clientBuilder.clients.first)
            return client?.platformClient.featureFlags == ["enableCipherKeyEncryption": true]
        }
        XCTAssertEqual(clientBuilder.clients.count, 1)
    }

    /// `configPublisher` does not load flags into the SDK when the config sent is pre authentication.
    @MainActor
    func test_configPublisher_doesNotloadFlagsWhenIsPreAuth() async throws {
        configService.configSubject.send(
            MetaServerConfig(
                isPreAuth: true,
                userId: "1",
                serverConfig: ServerConfig(
                    date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
                    responseModel: ConfigResponseModel(
                        environment: nil,
                        featureStates: [:],
                        gitHash: "75238191",
                        server: nil,
                        version: "2024.4.0"
                    )
                )
            )
        )

        XCTAssertTrue(clientBuilder.clients.isEmpty)
    }

    /// `configPublisher` does not load flags into the SDK when the config sent doesn't have a user id.
    @MainActor
    func test_configPublisher_doesNotloadFlagsWhenUserIdIsNil() async throws {
        configService.configSubject.send(
            MetaServerConfig(
                isPreAuth: false,
                userId: nil,
                serverConfig: ServerConfig(
                    date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
                    responseModel: ConfigResponseModel(
                        environment: nil,
                        featureStates: [:],
                        gitHash: "75238191",
                        server: nil,
                        version: "2024.4.0"
                    )
                )
            )
        )

        XCTAssertTrue(clientBuilder.clients.isEmpty)
    }

    /// `configPublisher` does not load flags into the SDK when the config sent doesn't have a server config.
    @MainActor
    func test_configPublisher_doesNotloadFlagsWhenServerConfigIsNil() async throws {
        configService.configSubject.send(
            MetaServerConfig(
                isPreAuth: false,
                userId: "1",
                serverConfig: nil
            )
        )

        try await waitForAsync {
            !self.clientBuilder.clients.isEmpty
        }

        let client = try XCTUnwrap(clientBuilder.clients.first)
        XCTAssertEqual(
            client.platformClient.featureFlags,
            [:]
        )
    }

    /// `crypto(for:)` returns a new `CryptoClientProtocol` for every user.
    func test_crypto() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let crypto = try await subject.crypto()

        XCTAssertIdentical(crypto, clientBuilder.clients.first?.cryptoClient)
        let user2Crypto = try await subject.crypto(for: "2")
        XCTAssertNotIdentical(crypto, user2Crypto)
    }

    /// `exporters(for:)` returns a new `ExporterClientProtocol` for every user.
    func test_exporters() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let exporters = try await subject.exporters()
        XCTAssertIdentical(exporters, clientBuilder.clients.first?.exporterClient)

        let user2Exporters = try await subject.exporters(for: "2")
        XCTAssertNotIdentical(exporters, user2Exporters)
    }

    /// `generators(for:)` returns a new `GeneratorClientsProtocol` for every user.
    func test_generators() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let generators = try await subject.generators(isPreAuth: false)
        XCTAssertIdentical(generators, clientBuilder.clients.first?.generatorClient)

        let user2Generators = try await subject.generators(for: "2")
        XCTAssertNotIdentical(generators, user2Generators)
    }

    /// `platform(for:)` returns a new `PlatformClientProtocol` for every user.
    func test_platform() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let platform = try await subject.platform()
        XCTAssertIdentical(platform, clientBuilder.clients.first?.platformClient)

        let user2Platform = try await subject.platform(for: "2")
        XCTAssertNotIdentical(platform, user2Platform)
    }

    /// `removeClient(for:)` removes a cached client for a user.
    func test_removeClient() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let crypto = try await subject.crypto()
        let crypto2 = try await subject.crypto()
        // The same client should be returned for subsequent requests.
        XCTAssertIdentical(crypto, crypto2)

        try await subject.removeClient()
        // After removing the client, a new client should be returned for the user.
        let cryptoAfterRemoving = try await subject.crypto()

        XCTAssertNotIdentical(crypto, cryptoAfterRemoving)
    }

    /// `sends(for:)` returns a new `VaultClientProtocol` for every user.
    func test_sends() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let sends = try await subject.sends()
        XCTAssertIdentical(sends, clientBuilder.clients.first?.sendClient)

        let user2Sends = try await subject.sends(for: "2")
        XCTAssertNotIdentical(sends, user2Sends)
    }

    /// `vault(for:)` returns a new `VaultClientProtocol` for every user.
    func test_vault() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let vault = try await subject.vault()
        XCTAssertIdentical(vault, clientBuilder.clients.first?.vaultClient)

        let user2Vault = try await subject.vault(for: "2")
        XCTAssertNotIdentical(vault, user2Vault)
    }
}
