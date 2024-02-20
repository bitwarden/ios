import XCTest

@testable import BitwardenShared

class MigrationServiceTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var errorReporter: MockErrorReporter!
    var keychainRepository: MockKeychainRepository!
    var subject: DefaultMigrationService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        errorReporter = MockErrorReporter()
        keychainRepository = MockKeychainRepository()

        subject = DefaultMigrationService(
            appSettingsStore: appSettingsStore,
            errorReporter: errorReporter,
            keychainRepository: keychainRepository
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        errorReporter = nil
        keychainRepository = nil
        subject = nil
    }

    // MARK: Tests

    /// `performMigrations()` logs an error to the error reporter if one occurs.
    func test_performMigrations_error() async throws {
        appSettingsStore.migrationVersion = 0
        appSettingsStore.state = .fixture(
            accounts: [
                "1": .fixture(
                    tokens: Account.AccountTokens(
                        accessToken: "ACCESS_TOKEN_1",
                        refreshToken: "REFRESH_TOKEN_1"
                    )
                ),
            ],
            activeUserId: "1"
        )
        keychainRepository.setAccessTokenResult = .failure(KeychainServiceError.osStatusError(-1))

        await subject.performMigrations()

        XCTAssertEqual(appSettingsStore.migrationVersion, 0)
        XCTAssertEqual(errorReporter.errors as? [KeychainServiceError], [KeychainServiceError.osStatusError(-1)])
    }

    /// `performMigrations()` performs migration 1 and moves the user's tokens to the keychain.
    func test_performMigrations_1_withAccounts() async throws {
        appSettingsStore.migrationVersion = 0
        appSettingsStore.state = .fixture(
            accounts: [
                "1": .fixture(
                    tokens: Account.AccountTokens(
                        accessToken: "ACCESS_TOKEN_1",
                        refreshToken: "REFRESH_TOKEN_1"
                    )
                ),
                "2": .fixture(
                    tokens: Account.AccountTokens(
                        accessToken: "ACCESS_TOKEN_2",
                        refreshToken: "REFRESH_TOKEN_2"
                    )
                ),
            ],
            activeUserId: "1"
        )

        await subject.performMigrations()

        XCTAssertEqual(appSettingsStore.migrationVersion, 1)

        let account1 = try XCTUnwrap(appSettingsStore.state?.accounts["1"])
        XCTAssertNil(account1._tokens)
        let account2 = try XCTUnwrap(appSettingsStore.state?.accounts["2"])
        XCTAssertNil(account2._tokens)

        try XCTAssertEqual(keychainRepository.getValue(for: .accessToken(userId: "1")), "ACCESS_TOKEN_1")
        try XCTAssertEqual(keychainRepository.getValue(for: .refreshToken(userId: "1")), "REFRESH_TOKEN_1")
        try XCTAssertEqual(keychainRepository.getValue(for: .accessToken(userId: "2")), "ACCESS_TOKEN_2")
        try XCTAssertEqual(keychainRepository.getValue(for: .refreshToken(userId: "2")), "REFRESH_TOKEN_2")
    }

    /// `performMigrations()` for migration 1 handles no existing accounts.
    func test_performMigrations_1_withNoAccounts() async throws {
        appSettingsStore.migrationVersion = 0
        appSettingsStore.state = nil

        await subject.performMigrations()

        XCTAssertEqual(appSettingsStore.migrationVersion, 1)
        XCTAssertNil(appSettingsStore.state)
    }
}
