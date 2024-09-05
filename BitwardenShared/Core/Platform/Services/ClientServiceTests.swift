import BitwardenSdk
import XCTest

@testable import BitwardenShared

final class ClientServiceTests: BitwardenTestCase {
    var clientBuilder: MockClientBuilder!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: DefaultClientService!
    var vaultTimeoutService: MockVaultTimeoutService!

    // MARK: Setup and Teardown

    override func setUp() {
        super.setUp()

        clientBuilder = MockClientBuilder()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()
        subject = DefaultClientService(
            clientBuilder: clientBuilder,
            errorReporter: errorReporter,
            stateService: stateService
        )
        vaultTimeoutService = MockVaultTimeoutService()
    }

    override func tearDown() {
        super.tearDown()

        clientBuilder = nil
        errorReporter = nil
        stateService = nil
        subject = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `auth(for:)` returns a new `ClientAuthProtocol` for every user.
    func test_auth() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let auth = try await subject.auth()
        XCTAssertIdentical(auth, clientBuilder.clients.first?.clientAuth)

        let user2Auth = try await subject.auth(for: "2")
        XCTAssertNotIdentical(auth, user2Auth)
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
        let noActiveUserAuth = try await subject.auth(isPreAuth: true)
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
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let crypto = try await subject.crypto()

        XCTAssertIdentical(crypto, clientBuilder.clients.first?.clientCrypto)
        let user2Crypto = try await subject.crypto(for: "2")
        XCTAssertNotIdentical(crypto, user2Crypto)
    }

    /// `exporters(for:)` returns a new `ClientExportersProtocol` for every user.
    func test_exporters() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let exporters = try await subject.exporters()
        XCTAssertIdentical(exporters, clientBuilder.clients.first?.clientExporters)

        let user2Exporters = try await subject.exporters(for: "2")
        XCTAssertNotIdentical(exporters, user2Exporters)
    }

    /// `generators(for:)` returns a new `ClientGeneratorsProtocol` for every user.
    func test_generators() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let generators = try await subject.generators()
        XCTAssertIdentical(generators, clientBuilder.clients.first?.clientGenerators)

        let user2Generators = try await subject.generators(for: "2")
        XCTAssertNotIdentical(generators, user2Generators)
    }

    /// `platform(for:)` returns a new `ClientPlatformProtocol` for every user.
    func test_platform() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let platform = try await subject.platform()
        XCTAssertIdentical(platform, clientBuilder.clients.first?.clientPlatform)

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

    /// `sends(for:)` returns a new `ClientVaultProtocol` for every user.
    func test_sends() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let sends = try await subject.sends()
        XCTAssertIdentical(sends, clientBuilder.clients.first?.clientSends)

        let user2Sends = try await subject.sends(for: "2")
        XCTAssertNotIdentical(sends, user2Sends)
    }

    /// `vault(for:)` returns a new `ClientVaultProtocol` for every user.
    func test_vault() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))

        let vault = try await subject.vault()
        XCTAssertIdentical(vault, clientBuilder.clients.first?.clientVault)

        let user2Vault = try await subject.vault(for: "2")
        XCTAssertNotIdentical(vault, user2Vault)
    }
}
