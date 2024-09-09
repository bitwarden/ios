import BitwardenSdk
import XCTest

@testable import BitwardenShared

final class ClientServiceTests: BitwardenTestCase {
    var clientBuilder: MockClientBuilder!
    var configService: MockConfigService!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: DefaultClientService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        clientBuilder = MockClientBuilder()
        configService = MockConfigService()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        subject = DefaultClientService(
            clientBuilder: clientBuilder,
            configService: configService,
            errorReporter: errorReporter,
            stateService: stateService
        )
        vaultTimeoutService = MockVaultTimeoutService()
    }

    override func tearDown() {
        super.tearDown()

        clientBuilder = nil
        configService = nil
        errorReporter = nil
        stateService = nil
        subject = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `auth(for:)` returns a new `ClientAuthProtocol` for every user.
    func test_auth() async throws {
        let auth = try await subject.auth()
        XCTAssertIdentical(auth, clientBuilder.clients.first?.clientAuth)

        let user2Auth = try await subject.auth(for: "2")
        XCTAssertNotIdentical(auth, user2Auth)
    }

    /// Tests that `client(for:)` creates a new client if there is no active user/if there are no users.
    /// Also tests that `client(for:)` returns a user's existing client.
    /// Also tests that a `client(for:)` creates a new client if a user doesn't  have one.
    func test_client_multiple_users() async throws {
        // No active user.
        let noActiveUserAuth = try await subject.auth()
        let auth = clientBuilder.clients.first?.clientAuth
        XCTAssertIdentical(noActiveUserAuth, auth)

        // Creates new client for user that doesn't have one.
        let userAuth = try await subject.auth(for: "1")
        XCTAssertNotIdentical(noActiveUserAuth, userAuth)

        // Creates a new client for a different user.
        let user2Auth = try await subject.auth(for: "2")
        XCTAssertNotIdentical(noActiveUserAuth, user2Auth)
        XCTAssertNotIdentical(userAuth, user2Auth)

        // Returns a user's existing client.
        let userExistingClientAuth = try await subject.auth(for: "1")
        XCTAssertIdentical(userAuth, userExistingClientAuth)
    }

    /// `crypto(for:)` returns a new `ClientCryptoProtocol` for every user.
    func test_crypto() async throws {
        let crypto = try await subject.crypto()

        XCTAssertIdentical(crypto, clientBuilder.clients.first?.clientCrypto)
        let user2Crypto = try await subject.crypto(for: "1")
        XCTAssertNotIdentical(crypto, user2Crypto)
    }

    /// `exporters(for:)` returns a new `ClientExportersProtocol` for every user.
    func test_exporters() async throws {
        let exporters = try await subject.exporters()
        XCTAssertIdentical(exporters, clientBuilder.clients.first?.clientExporters)

        let user2Exporters = try await subject.exporters(for: "1")
        XCTAssertNotIdentical(exporters, user2Exporters)
    }

    /// `generators(for:)` returns a new `ClientGeneratorsProtocol` for every user.
    func test_generators() async throws {
        let generators = try await subject.generators()
        XCTAssertIdentical(generators, clientBuilder.clients.first?.clientGenerators)

        let user2Generators = try await subject.generators(for: "1")
        XCTAssertNotIdentical(generators, user2Generators)
    }

    /// `platform(for:)` returns a new `ClientPlatformProtocol` for every user.
    func test_platform() async throws {
        let platform = try await subject.platform()
        XCTAssertIdentical(platform, clientBuilder.clients.first?.clientPlatform)

        let user2Platform = try await subject.platform(for: "1")
        XCTAssertNotIdentical(platform, user2Platform)
    }

    /// `sends(for:)` returns a new `ClientVaultProtocol` for every user.
    func test_sends() async throws {
        let sends = try await subject.sends()
        XCTAssertIdentical(sends, clientBuilder.clients.first?.clientSends)

        let user2Sends = try await subject.sends(for: "1")
        XCTAssertNotIdentical(sends, user2Sends)
    }

    /// `vault(for:)` returns a new `ClientVaultProtocol` for every user.
    func test_vault() async throws {
        let vault = try await subject.vault()
        XCTAssertIdentical(vault, clientBuilder.clients.first?.clientVault)

        let user2Vault = try await subject.vault(for: "1")
        XCTAssertNotIdentical(vault, user2Vault)
    }

//
//    /// `getConfig()` loads enableCipherKeyEncryption flag as `true` into the SDK.
//    func test_getConfig_loadFlagsEnableCipherKeyEncryptionTrue() async {
//        stateService.serverConfig["1"] = ServerConfig(
//            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
//            responseModel: ConfigResponseModel(
//                environment: nil,
//                featureStates: [:],
//                gitHash: "75238191",
//                server: nil,
//                version: "2024.4.0"
//            )
//        )
//
//        let response = await subject.getConfig(forceRefresh: false, isPreAuth: false)
//        XCTAssertEqual(
//            clientService.mockPlatform.featureFlags,
//            ["enableCipherKeyEncryption": true]
//        )
//    }
//
//    /// `getConfig()` loads enableCipherKeyEncryption flag as `false` into the SDK.
//    func test_getConfig_loadFlagsEnableCipherKeyEncryptionFalse() async {
//        stateService.serverConfig["1"] = ServerConfig(
//            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
//            responseModel: ConfigResponseModel(
//                environment: nil,
//                featureStates: [:],
//                gitHash: "75238191",
//                server: nil,
//                version: "2024.1.0"
//            )
//        )
//
//        let response = await subject.getConfig(forceRefresh: false, isPreAuth: false)
//        XCTAssertEqual(
//            clientService.mockPlatform.featureFlags,
//            ["enableCipherKeyEncryption": false]
//        )
//    }
//
//    /// `getConfig()` logs error when loadFlags throws.
//    func test_getConfig_loadFlagsError() async {
//        stateService.serverConfig["1"] = ServerConfig(
//            date: Date(year: 2024, month: 2, day: 14, hour: 7, minute: 50, second: 0),
//            responseModel: ConfigResponseModel(
//                environment: nil,
//                featureStates: [:],
//                gitHash: "75238191",
//                server: nil,
//                version: "2024.4.0"
//            )
//        )
//        clientService.mockPlatform.loadFlagsError = BitwardenTestError.example
//
//        let response = await subject.getConfig(forceRefresh: false, isPreAuth: false)
//        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
//    }
}
