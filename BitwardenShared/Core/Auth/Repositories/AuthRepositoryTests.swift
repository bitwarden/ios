import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AuthRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var accountAPIService: APIService!
    var authService: MockAuthService!
    var biometricsService: MockBiometricsService!
    var client: MockHTTPClient!
    var clientAuth: MockClientAuth!
    var clientCrypto: MockClientCrypto!
    var clientPlatform: MockClientPlatform!
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
        biometricsService = MockBiometricsService()
        clientCrypto = MockClientCrypto()
        clientPlatform = MockClientPlatform()
        environmentService = MockEnvironmentService()
        organizationService = MockOrganizationService()
        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultAuthRepository(
            accountAPIService: accountAPIService,
            authService: authService,
            biometricsService: biometricsService,
            clientAuth: clientAuth,
            clientCrypto: clientCrypto,
            clientPlatform: clientPlatform,
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
        biometricsService = nil
        client = nil
        clientAuth = nil
        clientCrypto = nil
        clientPlatform = nil
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

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_biometricsServiceError() async throws {
        biometricsService.setBiometricUnlockKeyError = BiometricsServiceError.setAuthKeyFailed
        await assertAsyncThrows(error: BiometricsServiceError.setAuthKeyFailed) {
            try await subject.allowBioMetricUnlock(true, userId: nil)
        }
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_cryptoError() async throws {
        biometricsService.setBiometricUnlockKeyError = nil
        struct ClientError: Error, Equatable {}
        clientCrypto.getUserEncryptionKeyResult = .failure(ClientError())
        await assertAsyncThrows(error: ClientError()) {
            try await subject.allowBioMetricUnlock(true, userId: "123")
        }
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_true_success() async throws {
        biometricsService.setBiometricUnlockKeyError = nil
        let key = "userKey"
        clientCrypto.getUserEncryptionKeyResult = .success(key)
        try await subject.allowBioMetricUnlock(true, userId: "123")
        XCTAssertEqual(biometricsService.capturedUserAuthKey, key)
        XCTAssertEqual("123", biometricsService.capturedUserID)
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_false_success() async throws {
        biometricsService.setBiometricUnlockKeyError = nil
        let key = "userKey"
        clientCrypto.getUserEncryptionKeyResult = .success(key)
        try await subject.allowBioMetricUnlock(false, userId: "456")
        XCTAssertNil(biometricsService.capturedUserAuthKey)
        XCTAssertEqual("456", biometricsService.capturedUserID)
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_false_success_biometricsServiceError() async throws {
        biometricsService.setBiometricUnlockKeyError = nil
        clientCrypto.getUserEncryptionKeyResult = .failure(BiometricsServiceError.getAuthKeyFailed)
        try await subject.allowBioMetricUnlock(false, userId: nil)
        XCTAssertNil(biometricsService.capturedUserAuthKey)
        XCTAssertNil(biometricsService.capturedUserID)
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

    /// `getFingerprintPhrase(userId:)` gets the account's fingerprint phrase.
    func test_getFingerprintPhrase() async throws {
        let account = Account.fixture()
        stateService.accounts = [account]
        _ = try await subject.setActiveAccount(userId: account.profile.userId)
        try await stateService.setAccountEncryptionKeys(AccountEncryptionKeys(
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "USER_KEY"
        ))

        let phrase = try await subject.getFingerprintPhrase(userId: account.profile.userId)
        XCTAssertEqual(clientPlatform.fingerprintMaterialString, account.profile.userId)
        XCTAssertEqual(try clientPlatform.fingerprintResult.get(), phrase)
    }

    /// `getFingerprintPhrase(userId:)` throws an error if there is no active account.
    func test_getFingerprintPhrase_throws() async throws {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getFingerprintPhrase(userId: "")
        }
    }

    /// `passwordStrength(email:password)` returns the calculated password strength.
    func test_passwordStrength() async {
        clientAuth.passwordStrengthResult = 0
        let weakPasswordStrength = await subject.passwordStrength(email: "user@bitwarden.com", password: "password")
        XCTAssertEqual(weakPasswordStrength, 0)
        XCTAssertEqual(clientAuth.passwordStrengthEmail, "user@bitwarden.com")
        XCTAssertEqual(clientAuth.passwordStrengthPassword, "password")

        clientAuth.passwordStrengthResult = 4
        let strongPasswordStrength = await subject.passwordStrength(
            email: "user@bitwarden.com",
            password: "ghu65zQ0*TjP@ij74g*&FykWss#Kgv8L8j8XmC03"
        )
        XCTAssertEqual(strongPasswordStrength, 4)
        XCTAssertEqual(clientAuth.passwordStrengthEmail, "user@bitwarden.com")
        XCTAssertEqual(
            clientAuth.passwordStrengthPassword,
            "ghu65zQ0*TjP@ij74g*&FykWss#Kgv8L8j8XmC03"
        )
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
            try await subject.unlockVault(password: "password")
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
        XCTAssertFalse(biometricsService.didConfigureBiometricIntegrity)
    }

    /// `unlockVault(password:)` configures biometric integrity refreshes.
    func test_unlockVault_integrityRefresh() async throws {
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(encryptedPrivateKey: "PRIVATE_KEY", encryptedUserKey: "USER_KEY"),
        ]
        biometricsService.biometricUnlockStatus = .success(
            .available(.faceID, enabled: true, hasValidIntegrity: false)
        )

        await assertAsyncDoesNotThrow {
            try await subject.unlockVault(password: "password")
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
        XCTAssertTrue(biometricsService.didConfigureBiometricIntegrity)
    }

    /// `lockVault(userId:)` locks the vault for the specified user id.
    func test_lockVault() async {
        await subject.lockVault(userId: "10")
        XCTAssertEqual(vaultTimeoutService.lockedIds, ["10"])
    }

    /// `unlockVaultWithBiometrics()` throws an error if the vault is unable to be unlocked.
    func test_unlockVaultWithBiometrics_error_cryptoFail() async {
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                encryptedPrivateKey: "private",
                encryptedUserKey: "user"
            ),
        ]
        stateService.activeAccount = .fixture()
        struct CryptoError: Error, Equatable {}
        clientCrypto.initializeUserCryptoResult = .failure(CryptoError())
        await assertAsyncThrows(error: CryptoError()) {
            _ = try await subject.unlockVaultWithBiometrics()
        }
    }

    /// `unlockVaultWithBiometrics()` throws an error if the vault is unable to be unlocked.
    func test_unlockVaultWithBiometrics_error_noAccount() async {
        stateService.activeAccount = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.unlockVaultWithBiometrics()
        }
    }

    /// `unlockVaultWithBiometrics()` throws an error if the vault is unable to be unlocked.
    func test_unlockVaultWithBiometrics_error_biometricsService_noKeys() async {
        stateService.activeAccount = .fixture()
        struct KeyError: Error, Equatable {}
        biometricsService.getUserAuthKeyResult = .failure(KeyError())
        await assertAsyncThrows(error: KeyError()) {
            _ = try await subject.unlockVaultWithBiometrics()
        }
    }

    /// `unlockVaultWithBiometrics()` throws an error if the vault is unable to be unlocked.
    func test_unlockVaultWithBiometrics_error_stateService_noKey() async {
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys = [:]
        biometricsService.getUserAuthKeyResult = .success("UserKey")
        clientCrypto.initializeUserCryptoResult = .success(())
        organizationService.initializeOrganizationCryptoError = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.unlockVaultWithBiometrics()
        }
    }

    /// `unlockVaultWithBiometrics()` throws an error if the vault is unable to be unlocked.
    func test_unlockVaultWithBiometrics_error_orgCryptoFail() async {
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys = [
            "1": .init(
                encryptedPrivateKey: "Private Key",
                encryptedUserKey: "Encrypted User Key"
            ),
        ]
        biometricsService.getUserAuthKeyResult = .success("UserKey")
        clientCrypto.initializeUserCryptoResult = .success(())
        struct OrgError: Error, Equatable {}
        organizationService.initializeOrganizationCryptoError = OrgError()
        await assertAsyncThrows(error: OrgError()) {
            _ = try await subject.unlockVaultWithBiometrics()
        }
    }

    /// `unlockVaultWithBiometrics()` throws no error if the user key is empty
    func test_unlockVaultWithBiometrics_emptyKey() async {
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                encryptedPrivateKey: "private",
                encryptedUserKey: "user"
            ),
        ]
        stateService.activeAccount = .fixture()
        biometricsService.getUserAuthKeyResult = .success("")
        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithBiometrics()
        }
    }

    /// `unlockVaultWithBiometrics()` throws no error if the vault is able to be unlocked.
    func test_unlockVaultWithBiometrics_success() async {
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                encryptedPrivateKey: "private",
                encryptedUserKey: "user"
            ),
        ]
        stateService.activeAccount = .fixture()
        clientCrypto.initializeUserCryptoResult = .success(())
        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithBiometrics()
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
        let account = Account.fixture()
        stateService.accounts = [account]
        stateService.activeAccount = account
        vaultTimeoutService.timeoutStore = [account.profile.userId: false]
        biometricsService.capturedUserAuthKey = "Value"
        biometricsService.setBiometricUnlockKeyError = nil
        let task = Task {
            try await subject.logout()
        }
        waitFor(!vaultTimeoutService.removedIds.isEmpty)
        task.cancel()

        XCTAssertEqual([account.profile.userId], stateService.accountsLoggedOut)
        XCTAssertNil(biometricsService.capturedUserAuthKey)
    }

    /// `unlockVault(password:)` throws an error if the vault is unable to be unlocked.
    func test_unlockVault_error() async {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.unlockVault(password: "")
        }
    }
} // swiftlint:disable:this file_length
