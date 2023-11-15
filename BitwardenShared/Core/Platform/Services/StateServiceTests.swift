import XCTest

@testable import BitwardenShared

class StateServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
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

    /// `getPasswordGenerationOptions()` gets the saved password generation options for the account.
    func test_getPasswordGenerationOptions() async throws {
        let options1 = PasswordGenerationOptions(length: 30)
        let options2 = PasswordGenerationOptions(length: 50)

        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        appSettingsStore.passwordGenerationOptions = [
            "1": options1,
            "2": options2,
        ]

        let fetchedOptions1 = try await subject.getPasswordGenerationOptions(userId: "1")
        XCTAssertEqual(fetchedOptions1, options1)

        let fetchedOptions2 = try await subject.getPasswordGenerationOptions(userId: "2")
        XCTAssertEqual(fetchedOptions2, options2)

        let fetchedOptionsActiveAccount = try await subject.getPasswordGenerationOptions()
        XCTAssertEqual(fetchedOptionsActiveAccount, options1)

        let fetchedOptionsNoAccount = try await subject.getPasswordGenerationOptions(userId: "-1")
        XCTAssertNil(fetchedOptionsNoAccount)
    }

    /// `getUsernameGenerationOptions()` gets the saved username generation options for the account.
    func test_getUsernameGenerationOptions() async throws {
        let options1 = UsernameGenerationOptions(plusAddressedEmail: "user@bitwarden.com")
        let options2 = UsernameGenerationOptions(catchAllEmailDomain: "bitwarden.com")

        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        appSettingsStore.usernameGenerationOptions = [
            "1": options1,
            "2": options2,
        ]

        let fetchedOptions1 = try await subject.getUsernameGenerationOptions(userId: "1")
        XCTAssertEqual(fetchedOptions1, options1)

        let fetchedOptions2 = try await subject.getUsernameGenerationOptions(userId: "2")
        XCTAssertEqual(fetchedOptions2, options2)

        let fetchedOptionsActiveAccount = try await subject.getUsernameGenerationOptions()
        XCTAssertEqual(fetchedOptionsActiveAccount, options1)

        let fetchedOptionsNoAccount = try await subject.getUsernameGenerationOptions(userId: "-1")
        XCTAssertNil(fetchedOptionsNoAccount)
    }

    /// `logoutAccount()` clears any account data.
    func test_logoutAccount_clearAccountData() async throws {
        let account = Account.fixture(profile: Account.AccountProfile.fixture(userId: "1"))
        await subject.addAccount(account)
        try await subject.setAccountEncryptionKeys(AccountEncryptionKeys(
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "USER_KEY"
        ))
        try await subject.setPasswordGenerationOptions(PasswordGenerationOptions(length: 30))

        try await subject.logoutAccount()

        XCTAssertEqual(appSettingsStore.encryptedPrivateKeys, [:])
        XCTAssertEqual(appSettingsStore.encryptedUserKeys, [:])
        XCTAssertEqual(appSettingsStore.passwordGenerationOptions, [:])
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

    /// `setActiveAccount(userId: )` returns without aciton if there are no accounts
    func test_setActiveAccount_noAccounts() async throws {
        let storeState = await subject.appSettingsStore.state
        XCTAssertNil(storeState)
    }

    /// `setActiveAccount(userId: )` fails if there are no matching accounts
    func test_setActiveAccount_noMatch() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        await assertAsyncThrows(error: StateServiceError.noAccounts) {
            try await subject.setActiveAccount(userId: "2")
        }
    }

    /// `setActiveAccount(userId: )` succeeds if there is a matching account
    func test_setActiveAccount_match_single() async throws {
        let account1 = Account.fixture(profile: .fixture(userId: "1"))
        await subject.addAccount(account1)

        var active = try await subject.getActiveAccount()
        XCTAssertEqual(active, account1)
        try await subject.setActiveAccount(userId: "1")
        active = try await subject.getActiveAccount()
        XCTAssertEqual(active, account1)
    }

    /// `setActiveAccount(userId: )` succeeds if there is a matching account
    func test_setActiveAccount_match_multi() async throws {
        let account1 = Account.fixture(profile: .fixture(userId: "1"))
        let account2 = Account.fixture(profile: .fixture(userId: "2"))
        await subject.addAccount(account1)
        await subject.addAccount(account2)

        var active = try await subject.getActiveAccount()
        XCTAssertEqual(active, account2)
        try await subject.setActiveAccount(userId: "1")
        active = try await subject.getActiveAccount()
        XCTAssertEqual(active, account1)
    }

    /// `setPasswordGenerationOptions` sets the password generation options for an account.
    func test_setPasswordGenerationOptions() async throws {
        let options1 = PasswordGenerationOptions(length: 30)
        let options2 = PasswordGenerationOptions(length: 50)

        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        try await subject.setPasswordGenerationOptions(options1)
        try await subject.setPasswordGenerationOptions(options2, userId: "2")

        XCTAssertEqual(appSettingsStore.passwordGenerationOptions["1"], options1)
        XCTAssertEqual(appSettingsStore.passwordGenerationOptions["2"], options2)
    }

    /// `setUsernameGenerationOptions` sets the username generation options for an account.
    func test_setUsernameGenerationOptions() async throws {
        let options1 = UsernameGenerationOptions(plusAddressedEmail: "user@bitwarden.com")
        let options2 = UsernameGenerationOptions(catchAllEmailDomain: "bitwarden.com")

        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        try await subject.setUsernameGenerationOptions(options1)
        try await subject.setUsernameGenerationOptions(options2, userId: "2")

        XCTAssertEqual(appSettingsStore.usernameGenerationOptions["1"], options1)
        XCTAssertEqual(appSettingsStore.usernameGenerationOptions["2"], options2)
    }
} // swiftlint:disable:this file_length
