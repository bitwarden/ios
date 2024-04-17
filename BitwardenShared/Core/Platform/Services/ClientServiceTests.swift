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

    /// `client(for:)` returns the user's client if they aleady have one.
    func test_client_existing_client() async throws {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId
        let client = clientBuilder.buildClient()
        let clientPlatform = try await subject.platform(for: userId)

        XCTAssertIdentical(clientPlatform, client.platform())
    }

    /// `client(for:)` creates a client if the user does not have one,
    /// or if there is no active account/if there are no accounts.
    func test_client_nonExistent_client() async throws {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        XCTAssertNil(subject.userClientArray[userId])

        _ = try await subject.auth(for: userId)

        XCTAssertNotNil(subject.userClientArray[userId])
    }

    /// `auth(for:)` returns a `ClientAuthProtocol`.
    func test_auth() async throws {
        let clientAuth = try await subject.auth()

        XCTAssertNotNil(clientAuth)
    }

    /// `crypto(for:)` returns a `ClientCryptoProtocol`.
    func test_crypto() async throws {
        await assertAsyncDoesNotThrow { _ = try await subject.crypto() }
    }

    /// `exporters(for:)` returns a `ClientExportersProtocol`.
    func test_exporters() async throws {
        let clientExporters = try await subject.exporters()

        XCTAssertNotNil(clientExporters)
    }

    /// `generators(for:)` returns a `ClientGeneratorsProtocol`.
    func test_generators() async throws {
        let clientGenerators = try await subject.generators()

        XCTAssertNotNil(clientGenerators)
    }

    /// `platform(for:)` returns a `ClientPlatformProtocol`.
    func test_platform() async throws {
        let clientPlatform = try await subject.platform()

        XCTAssertNotNil(clientPlatform)
    }

    /// `vault(for:)` returns a `ClientVaultProtocol`.
    func test_vault() async throws {
        let clientVault = try await subject.vault()

        XCTAssertNotNil(clientVault)
    }
}
