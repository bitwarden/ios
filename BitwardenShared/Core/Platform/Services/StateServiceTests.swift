import BitwardenSdk
import XCTest

@testable import BitwardenShared

class StateServiceTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var appSettingsStore: MockAppSettingsStore!
    var dataStore: DataStore!
    var subject: DefaultStateService!

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appSettingsStore = MockAppSettingsStore()
        dataStore = DataStore(errorReporter: MockErrorReporter(), storeType: .memory)

        subject = DefaultStateService(
            appSettingsStore: appSettingsStore,
            dataStore: dataStore
        )
    }

    override func tearDown() {
        super.tearDown()

        appSettingsStore = nil
        dataStore = nil
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

    /// `.deleteAccount()` deletes the active user's account, removing it from the state.
    func test_deleteAccount() async throws {
        let newAccount = Account.fixture(profile: Account.AccountProfile.fixture(userId: "1"))
        await subject.addAccount(newAccount)

        try await subject.deleteAccount()

        // User is removed from the state.
        let state = try XCTUnwrap(appSettingsStore.state)
        XCTAssertTrue(state.accounts.isEmpty)
        XCTAssertNil(state.activeUserId)
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

    /// `getAccounts()` returns the accounts when there's a single account.
    func test_getAccounts_singleAccount() async throws {
        let account = Account.fixture(profile: Account.AccountProfile.fixture(userId: "1"))
        appSettingsStore.state = State(accounts: [account.profile.userId: account], activeUserId: nil)

        let accounts = try await subject.getAccounts()
        XCTAssertEqual(accounts, [account])
    }

    /// `getAccounts()` throws an error when there are no accounts.
    func test_getAccounts_noAccounts() async throws {
        appSettingsStore.state = nil

        await assertAsyncThrows(error: StateServiceError.noAccounts) {
            _ = try await subject.getAccounts()
        }
    }

    /// `getAccountIdOrActiveId(userId:)` throws an error when there is no active account.
    func test_getAccountIdOrActiveId_nil_noActiveAccount() async throws {
        appSettingsStore.state = State(accounts: [:], activeUserId: nil)

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getAccountIdOrActiveId(userId: nil)
        }
    }

    /// `getAccountIdOrActiveId(userId:)` throws an error when there are no accounts.
    func test_getAccountIdOrActiveId_nil_noAccounts() async throws {
        appSettingsStore.state = nil

        await assertAsyncThrows(error: StateServiceError.noAccounts) {
            _ = try await subject.getAccountIdOrActiveId(userId: nil)
        }
    }

    /// `getAccountIdOrActiveId(userId:)` throws an error when there is no matching account.
    func test_getAccountIdOrActiveId_userId_noMatchingAccount() async throws {
        let account = Account.fixtureAccountLogin()
        appSettingsStore.state = State(accounts: [account.profile.userId: account], activeUserId: nil)

        await assertAsyncThrows(error: StateServiceError.noAccounts) {
            _ = try await subject.getAccountIdOrActiveId(userId: "123")
        }
    }

    /// `getAccountIdOrActiveId(userId:)` throws an error when there are no accounts.
    func test_getAccountIdOrActiveId_userId_noAccounts() async throws {
        appSettingsStore.state = nil

        await assertAsyncThrows(error: StateServiceError.noAccounts) {
            _ = try await subject.getAccountIdOrActiveId(userId: "123")
        }
    }

    /// `getAccountIdOrActiveId(userId:)` returns the id for a match
    func test_getAccountIdOrActiveId_userId_matchingAccount() async throws {
        let account = Account.fixtureAccountLogin()
        appSettingsStore.state = State(accounts: [account.profile.userId: account], activeUserId: nil)

        let accountId = try await subject.getAccountIdOrActiveId(userId: account.profile.userId)
        XCTAssertEqual(accountId, account.profile.userId)
    }

    /// `allowSyncOnRefreshes()` returns the allow sync on refresh value for the active account.
    func test_getAllowSyncOnRefresh() async throws {
        await subject.addAccount(.fixture())
        appSettingsStore.allowSyncOnRefreshes["1"] = true
        let value = try await subject.getAllowSyncOnRefresh()
        XCTAssertTrue(value)
    }

    /// `allowSyncOnRefreshes()` defaults to `false` if the active account doesn't have a value set.
    func test_getAllowSyncOnRefresh_notSet() async throws {
        await subject.addAccount(.fixture())
        let value = try await subject.getAllowSyncOnRefresh()
        XCTAssertFalse(value)
    }

    /// `getClearClipboardValue()` returns the clear clipboard value for the active account.
    func test_getClearClipboardValue() async throws {
        await subject.addAccount(.fixture())
        appSettingsStore.clearClipboardValues["1"] = .twoMinutes
        let value = try await subject.getClearClipboardValue()
        XCTAssertEqual(value, .twoMinutes)
    }

    /// `getClearClipboardValue()` returns `.never` if the active account doesn't have a value set.
    func test_getClearClipboardValue_notSet() async throws {
        await subject.addAccount(.fixture())
        let value = try await subject.getClearClipboardValue()
        XCTAssertEqual(value, .never)
    }

    /// `getEnvironmentUrls()` returns the environment URLs for the active account.
    func test_getEnvironmentUrls() async throws {
        let urls = EnvironmentUrlData(base: .example)
        let account = Account.fixture(settings: .fixture(environmentUrls: urls))
        appSettingsStore.state = State(
            accounts: [account.profile.userId: account],
            activeUserId: account.profile.userId
        )
        let accountUrls = try await subject.getEnvironmentUrls()
        XCTAssertEqual(accountUrls, urls)
    }

    /// `getEnvironmentUrls()` returns `nil` if the active account doesn't have URLs set.
    func test_getEnvironmentUrls_notSet() async throws {
        let account = Account.fixture(settings: .fixture(environmentUrls: nil))
        appSettingsStore.state = State(
            accounts: [account.profile.userId: account],
            activeUserId: account.profile.userId
        )
        let urls = try await subject.getEnvironmentUrls()
        XCTAssertNil(urls)
    }

    /// `getEnvironmentUrls()` returns `nil` if the user doesn't exist.
    func test_getEnvironmentUrls_noUser() async throws {
        let urls = try await subject.getEnvironmentUrls(userId: "-1")
        XCTAssertNil(urls)
    }

    /// `getMasterPasswordHash()` returns the user's master password hash.
    func test_getMasterPasswordHash() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        let noPasswordHash = try await subject.getMasterPasswordHash()
        XCTAssertNil(noPasswordHash)

        appSettingsStore.masterPasswordHashes["1"] = "abcd"
        let passwordHash = try await subject.getMasterPasswordHash()
        XCTAssertEqual(passwordHash, "abcd")
    }

    /// `getMasterPasswordHash()` throws an error if there isn't an active account.
    func test_getMasterPasswordHash_noAccount() async {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getMasterPasswordHash()
        }
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

    /// `getPreAuthEnvironmentUrls` returns the saved pre-auth URLs.
    func test_getPreAuthEnvironmentUrls() async {
        let urls = EnvironmentUrlData(base: .example)
        appSettingsStore.preAuthEnvironmentUrls = urls
        let preAuthUrls = await subject.getPreAuthEnvironmentUrls()
        XCTAssertEqual(preAuthUrls, urls)
    }

    /// `getPreAuthEnvironmentUrls` returns `nil` if the URLs haven't been set.
    func test_getPreAuthEnvironmentUrls_notSet() async {
        let urls = await subject.getPreAuthEnvironmentUrls()
        XCTAssertNil(urls)
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

    /// lastSyncTimePublisher()` returns a publisher for the user's last sync time.
    func test_lastSyncTimePublisher() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        var publishedValues = [Date?]()
        let publisher = try await subject.lastSyncTimePublisher()
            .sink(receiveValue: { date in
                publishedValues.append(date)
            })
        defer { publisher.cancel() }

        let date = Date(year: 2023, month: 12, day: 1)
        try await subject.setLastSyncTime(date)

        XCTAssertEqual(publishedValues, [nil, date])
    }

    /// lastSyncTimePublisher()` gets the initial stored value if a cached sync time doesn't exist.
    func test_lastSyncTimePublisher_fetchesInitialValue() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))
        let initialSync = Date(year: 2023, month: 12, day: 1)
        appSettingsStore.lastSyncTimeByUserId["1"] = initialSync

        var publishedValues = [Date?]()
        let publisher = try await subject.lastSyncTimePublisher()
            .sink(receiveValue: { date in
                publishedValues.append(date)
            })
        defer { publisher.cancel() }

        let updatedSync = Date(year: 2023, month: 12, day: 4)
        try await subject.setLastSyncTime(updatedSync)

        XCTAssertEqual(publishedValues, [initialSync, updatedSync])
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
        try await dataStore.insertPasswordHistory(
            userId: "1",
            passwordHistory: PasswordHistory(password: "PASSWORD", lastUsedDate: Date())
        )
        try await dataStore.persistentContainer.viewContext.performAndSave {
            let context = self.dataStore.persistentContainer.viewContext
            _ = try CipherData(context: context, userId: "1", cipher: .fixture(id: UUID().uuidString))
            _ = CollectionData(context: context, userId: "1", collection: .fixture())
            _ = FolderData(
                context: context,
                userId: "1",
                folder: Folder(id: "1", name: "FOLDER1", revisionDate: Date())
            )
            _ = SendData(context: context, userId: "1", send: .fixture())
        }

        try await subject.logoutAccount()

        XCTAssertEqual(appSettingsStore.encryptedPrivateKeys, [:])
        XCTAssertEqual(appSettingsStore.encryptedUserKeys, [:])
        XCTAssertEqual(appSettingsStore.passwordGenerationOptions, [:])

        let context = dataStore.persistentContainer.viewContext
        try XCTAssertEqual(context.count(for: CipherData.fetchByUserIdRequest(userId: "1")), 0)
        try XCTAssertEqual(context.count(for: CollectionData.fetchByUserIdRequest(userId: "1")), 0)
        try XCTAssertEqual(context.count(for: FolderData.fetchByUserIdRequest(userId: "1")), 0)
        try XCTAssertEqual(context.count(for: PasswordHistoryData.fetchByUserIdRequest(userId: "1")), 0)
        try XCTAssertEqual(context.count(for: SendData.fetchByUserIdRequest(userId: "1")), 0)
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

    func test_pinKeyEncryptedUserKey() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))
        appSettingsStore.pinKeyEncryptedUserKey["1"] = "123"
        let pin = try await subject.pinKeyEncryptedUserKey(userId: "1")
        XCTAssertEqual(pin, "123")
    }

    /// `rememberedOrgIdentifier` gets and sets the value as expected.
    func test_rememberedOrgIdentifier() {
        // Getting the value should get the value from the app settings store.
        appSettingsStore.rememberedOrgIdentifier = "ImALumberjack"
        XCTAssertEqual(subject.rememberedOrgIdentifier, "ImALumberjack")

        // Setting the value should update the value in the app settings store.
        subject.rememberedOrgIdentifier = "AndImOk"
        XCTAssertEqual(appSettingsStore.rememberedOrgIdentifier, "AndImOk")
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

    /// `setAllowSyncOnRefresh(_:userId:)` sets the allow sync on refresh value for a user.
    func test_setAllowSyncOnRefresh() async throws {
        await subject.addAccount(.fixture())

        try await subject.setAllowSyncOnRefresh(true)
        XCTAssertEqual(appSettingsStore.allowSyncOnRefreshes["1"], true)
    }

    /// `setClearClipboardValue(_:userId:)` sets the clear clipboard value for a user.
    func test_setClearClipboardValue() async throws {
        await subject.addAccount(.fixture())

        try await subject.setClearClipboardValue(.thirtySeconds)
        XCTAssertEqual(appSettingsStore.clearClipboardValues["1"], .thirtySeconds)
    }

    /// `setLastSyncTime(_:userId:)` sets the last sync time for a user.
    func test_setLastSyncTime() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        let date = Date(year: 2023, month: 12, day: 1)
        try await subject.setLastSyncTime(date)
        XCTAssertEqual(appSettingsStore.lastSyncTimeByUserId["1"], date)

        let date2 = Date(year: 2023, month: 12, day: 2)
        try await subject.setLastSyncTime(date2, userId: "1")
        XCTAssertEqual(appSettingsStore.lastSyncTimeByUserId["1"], date2)
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

    /// `setMasterPasswordHash(_:)` sets the master password hash for a user.
    func test_setMasterPasswordHash() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        try await subject.setMasterPasswordHash("abcd")
        XCTAssertEqual(appSettingsStore.masterPasswordHashes, ["1": "abcd"])

        try await subject.setMasterPasswordHash("1234", userId: "1")
        XCTAssertEqual(appSettingsStore.masterPasswordHashes, ["1": "1234"])
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

    func test_setPinKeyEncryptedUserKey() async throws {
        await subject.addAccount(.fixture(profile: .fixture(userId: "1")))

        try await subject.setPinKeyEncryptedUserKey("123", userId: "1")
        XCTAssertEqual(appSettingsStore.pinKeyEncryptedUserKey["1"], "123")
    }

    /// `setPreAuthEnvironmentUrls` saves the pre-auth URLs.
    func test_setPreAuthEnvironmentUrls() async {
        let urls = EnvironmentUrlData(base: .example)
        await subject.setPreAuthEnvironmentUrls(urls)
        XCTAssertEqual(appSettingsStore.preAuthEnvironmentUrls, urls)
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
