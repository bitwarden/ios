import XCTest

@testable import BitwardenShared

class StateServiceTests: BitwardenTestCase {
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var subject: DefaultStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()

        subject = DefaultStateService(appSettingsStore: appSettingsStore)
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        subject = nil
    }

    // MARK: Tests

    /// `addAccount(_:)` adds an initial account and makes it the active account.
    func test_addAccount_initialAccount() async throws {
        let account = Account.fixture(profile: Account.AccountProfile.fixture(userId: "1"))
        await subject.addAccount(account)

        let state = try XCTUnwrap(appSettingsStore.state)
        XCTAssertEqual(state.accounts, ["1": account])
        XCTAssertEqual(state.activeUserId, "1")
    }

    /// `addAccount(_:)` adds new account to the account list with existing accounts and makes it
    /// the active account.
    func test_addAccount_multipleAccounts() async throws {
        let existingAccount = Account.fixture(profile: Account.AccountProfile.fixture(userId: "1"))
        await subject.addAccount(existingAccount)

        let newAccount = Account.fixture(profile: Account.AccountProfile.fixture(userId: "2"))
        await subject.addAccount(newAccount)

        let state = try XCTUnwrap(appSettingsStore.state)
        XCTAssertEqual(state.accounts, ["1": existingAccount, "2": newAccount])
        XCTAssertEqual(state.activeUserId, "2")
    }

    /// `getAccountEncryptionKeys(_:)` returns the encryption keys for the user account.
    func test_getAccountEncryptionKeys() async throws {
        appSettingsStore.encryptedPrivateKeys["1"] = "1:PRIVATE_KEY"
        appSettingsStore.encryptedPrivateKeys["2"] = "2:PRIVATE_KEY"
        appSettingsStore.encryptedUserKeys["1"] = "1:USER_KEY"
        appSettingsStore.encryptedUserKeys["2"] = "2:USER_KEY"

        appSettingsStore.state?.activeUserId = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getAccountEncryptionKeys()
        }

        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))
        let accountKeys = try await subject.getAccountEncryptionKeys()
        XCTAssertEqual(
            accountKeys,
            AccountEncryptionKeys(
                encryptedPrivateKey: "1:PRIVATE_KEY",
                encryptedUserKey: "1:USER_KEY"
            )
        )

        await subject.addAccount(.fixture(profile: .fixture(userId: "2")))
        let otherAccountKeys = try await subject.getAccountEncryptionKeys()
        XCTAssertEqual(
            otherAccountKeys,
            AccountEncryptionKeys(
                encryptedPrivateKey: "2:PRIVATE_KEY",
                encryptedUserKey: "2:USER_KEY"
            )
        )

        let accountKeysForUserId = try await subject.getAccountEncryptionKeys(userId: "1")
        XCTAssertEqual(
            accountKeysForUserId,
            AccountEncryptionKeys(
                encryptedPrivateKey: "1:PRIVATE_KEY",
                encryptedUserKey: "1:USER_KEY"
            )
        )
    }

    /// `getActiveAccount()` returns the active account.
    func test_getActiveAccount() async throws {
        let account = Account.fixture(profile: .fixture(userId: "2"))
        appSettingsStore.state = State.fixture(
            accounts: [
                "1": Account.fixture(),
                "2": account,
            ],
            activeUserId: "2"
        )

        let activeAccount = try await subject.getActiveAccount()
        XCTAssertEqual(activeAccount, account)
    }

    /// `getActiveAccount()` throws an error if there aren't any accounts.
    func test_getActiveAccount_noAccounts() async throws {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getActiveAccount()
        }
    }

    /// `getActiveAccount()` returns the active account when there's a single account.
    func test_getActiveAccount_singleAccount() async throws {
        let account = Account.fixture(profile: Account.AccountProfile.fixture(userId: "1"))
        await subject.addAccount(account)

        let activeAccount = try await subject.getActiveAccount()
        XCTAssertEqual(activeAccount, account)
    }

    /// `logoutAccount(_:)` removes the account from the account list and sets the active account to
    /// `nil` if there are no other accounts.
    func test_logoutAccount_singleAccount() async throws {
        let account = Account.fixture(profile: Account.AccountProfile.fixture(userId: "1"))
        await subject.addAccount(account)
        try await subject.setAccountEncryptionKeys(AccountEncryptionKeys(
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "USER_KEY"
        ))

        try await subject.logoutAccount(userId: "1")

        // User is removed from the state.
        let state = try XCTUnwrap(appSettingsStore.state)
        XCTAssertTrue(state.accounts.isEmpty)
        XCTAssertNil(state.activeUserId)

        // Additional user keys are removed.
        XCTAssertEqual(appSettingsStore.encryptedPrivateKeys, [:])
        XCTAssertEqual(appSettingsStore.encryptedUserKeys, [:])
    }

    /// `logoutAccount(_:)` removes the account from the account list and updates the active account
    /// to the first remaining account.
    func test_logoutAccount_multipleAccounts() async throws {
        let firstAccount = Account.fixture(profile: Account.AccountProfile.fixture(userId: "1"))
        await subject.addAccount(firstAccount)
        try await subject.setAccountEncryptionKeys(AccountEncryptionKeys(
            encryptedPrivateKey: "1:PRIVATE_KEY",
            encryptedUserKey: "1:USER_KEY"
        ))

        let secondAccount = Account.fixture(profile: Account.AccountProfile.fixture(userId: "2"))
        await subject.addAccount(secondAccount)
        try await subject.setAccountEncryptionKeys(AccountEncryptionKeys(
            encryptedPrivateKey: "2:PRIVATE_KEY",
            encryptedUserKey: "2:USER_KEY"
        ))

        try await subject.logoutAccount(userId: "2")

        // User is removed from the state.
        let state = try XCTUnwrap(appSettingsStore.state)
        XCTAssertEqual(state.accounts, ["1": firstAccount])
        XCTAssertEqual(state.activeUserId, "1")

        // Additional user keys are removed.
        XCTAssertEqual(appSettingsStore.encryptedPrivateKeys, ["1": "1:PRIVATE_KEY"])
        XCTAssertEqual(appSettingsStore.encryptedUserKeys, ["1": "1:USER_KEY"])
    }

    /// `logoutAccount(_:)` removes an inactive account from the account list and doesn't change
    /// the active account.
    func test_logoutAccount_inactiveAccount() async throws {
        let firstAccount = Account.fixture(profile: Account.AccountProfile.fixture(userId: "1"))
        await subject.addAccount(firstAccount)
        try await subject.setAccountEncryptionKeys(AccountEncryptionKeys(
            encryptedPrivateKey: "1:PRIVATE_KEY",
            encryptedUserKey: "1:USER_KEY"
        ))

        let secondAccount = Account.fixture(profile: Account.AccountProfile.fixture(userId: "2"))
        await subject.addAccount(secondAccount)
        try await subject.setAccountEncryptionKeys(AccountEncryptionKeys(
            encryptedPrivateKey: "2:PRIVATE_KEY",
            encryptedUserKey: "2:USER_KEY"
        ))

        try await subject.logoutAccount(userId: "1")

        // User is removed from the state.
        let state = try XCTUnwrap(appSettingsStore.state)
        XCTAssertEqual(state.accounts, ["2": secondAccount])
        XCTAssertEqual(state.activeUserId, "2")

        // Additional user keys are removed.
        XCTAssertEqual(appSettingsStore.encryptedPrivateKeys, ["2": "2:PRIVATE_KEY"])
        XCTAssertEqual(appSettingsStore.encryptedUserKeys, ["2": "2:USER_KEY"])
    }

    /// `setAccountEncryptionKeys(_:userId:)` sets the encryption keys for the user account.
    func test_setAccountEncryptionKeys() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))
        await subject.addAccount(.fixture(profile: .fixture(userId: "2")))

        let encryptionKeys = AccountEncryptionKeys(
            encryptedPrivateKey: "1:PRIVATE_KEY",
            encryptedUserKey: "1:USER_KEY"
        )
        try await subject.setAccountEncryptionKeys(encryptionKeys, userId: "1")

        let otherEncryptionKeys = AccountEncryptionKeys(
            encryptedPrivateKey: "2:PRIVATE_KEY",
            encryptedUserKey: "2:USER_KEY"
        )
        try await subject.setAccountEncryptionKeys(otherEncryptionKeys)

        XCTAssertEqual(
            appSettingsStore.encryptedPrivateKeys,
            [
                "1": "1:PRIVATE_KEY",
                "2": "2:PRIVATE_KEY",
            ]
        )
        XCTAssertEqual(
            appSettingsStore.encryptedUserKeys,
            [
                "1": "1:USER_KEY",
                "2": "2:USER_KEY",
            ]
        )
    }

    /// `setTokens(accessToken:refreshToken)` throws an error if there isn't an active account.
    func test_setAccountTokens_noAccount() async {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.setTokens(accessToken: "🔑", refreshToken: "🔒")
        }
    }

    /// `setTokens(accessToken:refreshToken)` sets the tokens for a single account.
    func test_setAccountTokens_singleAccount() async throws {
        await subject.addAccount(.fixture())

        try await subject.setTokens(accessToken: "🔑", refreshToken: "🔒")

        let account = try XCTUnwrap(appSettingsStore.state?.accounts["1"])
        XCTAssertEqual(
            account,
            Account.fixture(tokens: Account.AccountTokens(accessToken: "🔑", refreshToken: "🔒"))
        )
    }

    /// `setTokens(accessToken:refreshToken)` sets the tokens for an account where there are multiple accounts.
    func test_setAccountTokens_multipleAccount() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))
        await subject.addAccount(.fixture(profile: .fixture(userId: "2")))

        try await subject.setTokens(accessToken: "🔑", refreshToken: "🔒")

        let account = try XCTUnwrap(appSettingsStore.state?.accounts["2"])
        XCTAssertEqual(
            account,
            Account.fixture(
                profile: .fixture(userId: "2"),
                tokens: Account.AccountTokens(accessToken: "🔑", refreshToken: "🔒")
            )
        )
    }
}
