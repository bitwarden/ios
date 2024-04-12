import BitwardenSdk
import XCTest

@testable import BitwardenShared

final class ClientServiceTests: BitwardenTestCase {
    var clientBuilder: MockClientBuilder!
    var errorReporter: MockErrorReporter!
    var stateService: MockStateService!
    var subject: DefaultClientService!

    // MARK: Setup and Teardown

    override func setUp() {
        clientBuilder = MockClientBuilder()
        errorReporter = MockErrorReporter()
        stateService = MockStateService()

        subject = DefaultClientService(
            clientBuilder: clientBuilder,
            errorReporter: errorReporter,
            stateService: stateService
        )
    }

    override func tearDown() {
        clientBuilder = nil
        errorReporter = nil
        stateService = nil
        subject = nil
    }

    // MARK: Tests

    /// `client(for:)` returns the user's client if they aleady have one.
    func test_client_existing_client() async throws {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId
        let client = clientBuilder.buildClient()

        stateService.activeAccount = account
        subject.userClientDictionary.updateValue((client, true), forKey: userId)

        let clientPlatform = try await subject.clientPlatform(for: userId)

        XCTAssertIdentical(clientPlatform, client.platform())
    }

    /// `client(for:)` creates a client if the user does not have one.
    func test_client_nonExistent_client() async throws {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        stateService.activeAccount = account

        XCTAssertNil(subject.userClientDictionary[userId])

        _ = try await subject.clientAuth(for: userId)

        XCTAssertNotNil(subject.userClientDictionary[userId])
    }

    /// `client(for:)` returns a new client if there is no active account or
    /// if there are no accounts.
    func test_client_noAccount() async throws {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        XCTAssertNil(subject.userClientDictionary[userId])

        let clientCrypto = try await subject.clientCrypto()
        XCTAssertNotNil(clientCrypto)
    }

    /// `clientAuth(for:)` returns a `ClientAuthProtocol`.
    func test_clientAuth() async throws {
        let account = Account.fixtureAccountLogin()

        stateService.activeAccount = account
        let clientAuth = try await subject.clientAuth()

        XCTAssertNotNil(clientAuth)
    }

    /// `clientCrypto(for:)` returns a `ClientCryptoProtocol`.
    func test_clientCrypto() async throws {
        let account = Account.fixtureAccountLogin()

        stateService.activeAccount = account
        let clientCrypto = try await subject.clientCrypto()

        XCTAssertNotNil(clientCrypto)
    }

    /// `clientExporters(for:)` returns a `ClientExportersProtocol`.
    func test_clientExporters() async throws {
        let account = Account.fixtureAccountLogin()

        stateService.activeAccount = account
        let clientExporters = try await subject.clientExporters()

        XCTAssertNotNil(clientExporters)
    }

    /// `clientGenerators(for:)` returns a `ClientGeneratorsProtocol`.
    func test_clientGenerators() async throws {
        let account = Account.fixtureAccountLogin()

        stateService.activeAccount = account
        let clientGenerators = try await subject.clientGenerator()

        XCTAssertNotNil(clientGenerators)
    }

    /// `clientPlatform(for:)` returns a `ClientPlatformProtocol`.
    func test_clientPlatform() async throws {
        let account = Account.fixtureAccountLogin()

        stateService.activeAccount = account
        let clientPlatform = try await subject.clientPlatform()

        XCTAssertNotNil(clientPlatform)
    }

    /// `clientVault(for:)` returns a `ClientVaultProtocol`.
    func test_clientVault() async throws {
        let account = Account.fixtureAccountLogin()

        stateService.activeAccount = account
        let clientVault = try await subject.clientVault()

        XCTAssertNotNil(clientVault)
    }

    /// `isLocked(userId:)` returns whether or not the client is locked.
    func test_isLocked() async throws {
        let account = Account.fixtureAccountLogin()
        let userId = account.profile.userId

        _ = try await subject.clientAuth(for: userId)

        subject.updateClientLockedStatus(userId: userId, isLocked: true)

        XCTAssertTrue(subject.isLocked(userId: userId))

        subject.updateClientLockedStatus(userId: userId, isLocked: false)

        XCTAssertFalse(subject.isLocked(userId: userId))
    }
}
