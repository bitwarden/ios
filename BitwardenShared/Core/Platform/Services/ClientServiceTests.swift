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
        let auth = try await subject.auth()
        XCTAssertIdentical(auth, clientBuilder.client.auth())

        clientBuilder.client = MockClient()

        let user2Auth = try await subject.auth(for: "1")
        XCTAssertNotIdentical(auth, user2Auth)
    }

    /// `crypto(for:)` returns a new `ClientCryptoProtocol` for every user.
    func test_crypto() async throws {
        let crypto = try await subject.crypto()
        XCTAssertIdentical(crypto, clientBuilder.client.crypto())

        clientBuilder.client = MockClient()

        let user2Crypto = try await subject.crypto(for: "1")
        XCTAssertNotIdentical(crypto, user2Crypto)
    }

    /// `exporters(for:)` returns a new `ClientExportersProtocol` for every user.
    func test_exporters() async throws {
        let exporters = try await subject.exporters()
        XCTAssertIdentical(exporters, clientBuilder.client.exporters())

        clientBuilder.client = MockClient()

        let user2Exporters = try await subject.exporters(for: "1")
        XCTAssertNotIdentical(exporters, user2Exporters)
    }

    /// `generators(for:)` returns a new `ClientGeneratorsProtocol` for every user.
    func test_generators() async throws {
        let generators = try await subject.generators()
        XCTAssertIdentical(generators, clientBuilder.client.generators())

        clientBuilder.client = MockClient()

        let user2Generators = try await subject.generators(for: "1")
        XCTAssertNotIdentical(generators, user2Generators)
    }

    /// `platform(for:)` returns a new `ClientPlatformProtocol` for every user.
    func test_platform() async throws {
        let platform = try await subject.platform()
        XCTAssertIdentical(platform, clientBuilder.client.platform())

        clientBuilder.client = MockClient()

        let user2Platform = try await subject.platform(for: "1")
        XCTAssertNotIdentical(platform, user2Platform)
    }

    /// `vault(for:)` returns a new `ClientVaultProtocol` for every user.
    func test_vault() async throws {
        let vault = try await subject.vault()
        XCTAssertIdentical(vault, clientBuilder.client.vault())

        clientBuilder.client = MockClient()

        let user2Vault = try await subject.vault(for: "1")
        XCTAssertNotIdentical(vault, user2Vault)
    }
}
