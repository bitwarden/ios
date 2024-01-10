import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AuthRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var accountAPIService: APIService!
    var authService: MockAuthService!
    var client: MockHTTPClient!
    var clientAuth: MockClientAuth!
    var clientCrypto: MockClientCrypto!
    var environmentService: MockEnvironmentService!
    var organizationService: MockOrganizationService!
    var subject: DefaultAuthRepository!
    var stateService: MockStateService!
    var vaultTimeoutService: MockVaultTimeoutService!

    let anneAccount = Account
        .fixture(
            profile: .fixture(
                email: "Anne.Account@bitwarden.com",
                name: "Anne Account",
                userId: "1"
            )
        )

    let beeAccount = Account
        .fixture(
            profile: .fixture(
                email: "bee.account@bitwarden.com",
                userId: "2"
            )
        )

    let claimedAccount = Account
        .fixture(
            profile: .fixture(
                email: "claims@bitwarden.com",
                userId: "3"
            )
        )

    let empty = Account
        .fixture(
            profile: .fixture(
                email: "",
                userId: "4"
            )
        )

    let shortEmail = Account
        .fixture(
            profile: .fixture(
                email: "a@gmail.com",
                userId: "5"
            )
        )

    let shortName = Account
        .fixture(
            profile: .fixture(
                email: "aj@gmail.com",
                name: "AJ",
                userId: "6"
            )
        )

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        clientAuth = MockClientAuth()
        accountAPIService = APIService(client: client)
        authService = MockAuthService()
        clientCrypto = MockClientCrypto()
        environmentService = MockEnvironmentService()
        organizationService = MockOrganizationService()
        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultAuthRepository(
            accountAPIService: accountAPIService,
            authService: authService,
            clientAuth: clientAuth,
            clientCrypto: clientCrypto,
            environmentService: environmentService,
            organizationService: organizationService,
            stateService: stateService,
            vaultTimeoutService: vaultTimeoutService
        )
    }

    override func tearDown() {
        super.tearDown()

        accountAPIService = nil
        authService = nil
        client = nil
        clientAuth = nil
        clientCrypto = nil
        environmentService = nil
        organizationService = nil
        subject = nil
        stateService = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `deleteAccount()` deletes the active account and removes it from the state.
    func test_deleteAccount() async throws {
        stateService.accounts = [anneAccount, beeAccount]
        stateService.activeAccount = anneAccount

        client.result = .httpSuccess(testData: APITestData(data: Data()))

        try await subject.deleteAccount(passwordText: "12345")
        let accounts = try await stateService.getAccounts()

        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/api/accounts"))
    }

    /// `getAccounts()` throws an error when the accounts are nil.
    func test_getAccounts_empty() async throws {
        await assertAsyncThrows(error: StateServiceError.noAccounts) {
            _ = try await subject.getAccounts()
        }
    }

    /// `getAccounts()` returns all known accounts.
    func test_getAccounts_valid() async throws { // swiftlint:disable:this function_body_length
        stateService.accounts = [
            anneAccount,
            beeAccount,
            claimedAccount,
            empty,
            shortEmail,
            shortName,
        ]

        let accounts = try await subject.getAccounts()
        XCTAssertEqual(
            accounts.first,
            ProfileSwitcherItem(
                email: anneAccount.profile.email,
                userId: anneAccount.profile.userId,
                userInitials: "AA"
            )
        )
        XCTAssertEqual(
            accounts[1],
            ProfileSwitcherItem(
                email: beeAccount.profile.email,
                userId: beeAccount.profile.userId,
                userInitials: "BA"
            )
        )
        XCTAssertEqual(
            accounts[2],
            ProfileSwitcherItem(
                email: claimedAccount.profile.email,
                userId: claimedAccount.profile.userId,
                userInitials: "CL"
            )
        )
        XCTAssertEqual(
            accounts[3],
            ProfileSwitcherItem(
                email: "",
                userId: "4",
                userInitials: ".."
            )
        )
        XCTAssertEqual(
            accounts[4],
            ProfileSwitcherItem(
                email: shortEmail.profile.email,
                userId: shortEmail.profile.userId,
                userInitials: "A"
            )
        )
        XCTAssertEqual(
            accounts[5],
            ProfileSwitcherItem(
                email: shortName.profile.email,
                userId: shortName.profile.userId,
                userInitials: "AJ"
            )
        )
    }

    /// `getAccounts()` can return locked accounts correctly.
    func test_getAccounts_locked() async throws {
        stateService.accounts = [
            anneAccount,
            beeAccount,
            empty,
            shortEmail,
            shortName,
        ]
        vaultTimeoutService.timeoutStore = [
            anneAccount.profile.userId: true,
            beeAccount.profile.userId: false,
            shortEmail.profile.userId: true,
            shortName.profile.userId: false,
        ]
        let profiles = try await subject.getAccounts()
        let lockedStatuses = profiles.map { profile in
            profile.isUnlocked
        }
        XCTAssertEqual(
            lockedStatuses,
            [
                false,
                true,
                false,
                false,
                true,
            ]
        )
    }

    /// `getActiveAccount()` returns a profile switcher item.
    func test_getActiveAccount_empty() async throws {
        stateService.accounts = [
            anneAccount,
        ]

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getActiveAccount()
        }
    }

    /// `getActiveAccount()` returns an account when the active account is valid.
    func test_getActiveAccount_valid() async throws {
        stateService.accounts = [
            anneAccount,
        ]
        stateService.activeAccount = anneAccount

        let active = try await subject.getActiveAccount()
        XCTAssertEqual(
            active,
            ProfileSwitcherItem(
                email: anneAccount.profile.email,
                userId: anneAccount.profile.userId,
                userInitials: "AA"
            )
        )
    }

    /// `getAccount(for:)` returns an account when there is a match.
    func test_getAccountForProfile_match() async throws {
        stateService.accounts = [
            anneAccount,
        ]
        stateService.activeAccount = anneAccount
        let profile = ProfileSwitcherItem(
            email: anneAccount.profile.email,
            userId: anneAccount.profile.userId,
            userInitials: "AA"
        )

        let match = try await subject.getAccount(for: profile.userId)
        XCTAssertEqual(
            match,
            anneAccount
        )
    }

    /// `getAccount(for:)` returns an error when there is no match.
    func test_getAccountForProfile_noMatch() async throws {
        stateService.accounts = [
            anneAccount,
        ]
        stateService.activeAccount = anneAccount
        let profile = ProfileSwitcherItem(
            email: beeAccount.profile.email,
            userId: beeAccount.profile.userId,
            userInitials: "BA"
        )
        await assertAsyncThrows(error: StateServiceError.noAccounts) {
            _ = try await subject.getAccount(for: profile.userId)
        }
    }

    /// `setActiveAccount(userId: )` loads the environment URLs for the active account.
    func test_setActiveAccount_loadsEnvironmentUrls() async throws {
        let urls = EnvironmentUrlData(base: .example)
        let account = Account.fixture(settings: .fixture(environmentUrls: urls))
        stateService.accounts = [account]
        _ = try await subject.setActiveAccount(userId: account.profile.userId)
        XCTAssertTrue(environmentService.didLoadURLsForActiveAccount)
    }

    /// `setActiveAccount(userId: )` succeeds when there is a match.
    func test_setActiveAccount_match_active() async throws {
        stateService.accounts = [
            anneAccount,
        ]
        stateService.activeAccount = anneAccount
        _ = try await subject.setActiveAccount(userId: anneAccount.profile.userId)
        XCTAssertEqual(stateService.activeAccount, anneAccount)
    }

    /// `setActiveAccount(userId: )` succeeds when there is a match.
    func test_setActiveAccount_match_inactive() async throws {
        stateService.accounts = [
            anneAccount,
            beeAccount,
        ]
        stateService.activeAccount = anneAccount
        _ = try await subject.setActiveAccount(userId: beeAccount.profile.userId)
        XCTAssertEqual(stateService.activeAccount, beeAccount)
    }

    /// `setActiveAccount(userId: )` returns an error when there is no match.
    func test_setActiveAccount_noMatch_incorrectId() async throws {
        stateService.accounts = [
            anneAccount,
        ]
        stateService.activeAccount = anneAccount
        await assertAsyncThrows(error: StateServiceError.noAccounts) {
            _ = try await subject.setActiveAccount(userId: "1234")
        }
    }

    /// `setActiveAccount(userId: )` returns an error when there is no match.
    func test_setActiveAccount_noMatch_noAccounts() async throws {
        stateService.accounts = []
        stateService.activeAccount = nil
        await assertAsyncThrows(error: StateServiceError.noAccounts) {
            _ = try await subject.setActiveAccount(userId: anneAccount.profile.userId)
        }
    }

    /// `unlockVault(password:)` unlocks the vault with the user's password.
    func test_unlockVault() async throws {
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(encryptedPrivateKey: "PRIVATE_KEY", encryptedUserKey: "USER_KEY"),
        ]

        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithPassword(password: "password")
        }

        XCTAssertEqual(
            clientCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                privateKey: "PRIVATE_KEY",
                method: .password(password: "password", userKey: "USER_KEY")
            )
        )
        XCTAssertEqual(vaultTimeoutService.timeoutStore, ["1": false])
        XCTAssertTrue(organizationService.initializeOrganizationCryptoCalled)
        XCTAssertEqual(authService.hashPasswordPassword, "password")
        XCTAssertEqual(stateService.masterPasswordHashes["1"], "hashed")
    }

    /// `unlockVault(password:)` throws an error if the vault is unable to be unlocked.
    func test_unlockVault_error() async {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.unlockVaultWithPassword(password: "")
        }
    }

    /// `logout` throws an error with no accounts.
    func test_logout_noAccounts() async {
        stateService.accounts = []
        stateService.activeAccount = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.logout()
        }
    }

    /// `logout` throws an error with no active account.
    func test_logout_noActiveAccount() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        stateService.activeAccount = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.logout()
        }
    }

    /// `logout` successfully logs out a user.
    func test_logout_success() {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        stateService.activeAccount = account
        vaultTimeoutService.timeoutStore = [account.profile.userId: false]
        let task = Task {
            try await subject.logout()
        }
        waitFor(!vaultTimeoutService.removedIds.isEmpty)
        task.cancel()

        XCTAssertEqual([account.profile.userId], stateService.accountsLoggedOut)
    }

    /// `.setPin(_:)` sets the pin protected user key.
    func test_setPinProtectedUserKey() async throws {
        stateService.activeAccount = Account.fixture()
        clientCrypto.derivePinKeyResult = .success(DerivePinKeyResponse(pinProtectedUserKey: "12", encryptedPin: "34"))
        try await subject.setPin("99")
        XCTAssertEqual(stateService.pinProtectedUserKey["1"], "12")
    }

    /// `unlockWithPIN(_:)` unlocks the vault with the user's PIN.
    func test_unlockWithPIN() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(encryptedPrivateKey: "PRIVATE_KEY", encryptedUserKey: "USER_KEY"),
        ]
        stateService.pinProtectedUserKey[account.profile.userId] = "456"

        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithPIN(pin: "123")
        }

        XCTAssertEqual(
            clientCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                privateKey: "PRIVATE_KEY",
                method: .pin(pin: "123", pinProtectedUserKey: "456")
            )
        )
        XCTAssertEqual(vaultTimeoutService.timeoutStore, ["1": false])
    }
} // swiftlint:disable:this file_length
