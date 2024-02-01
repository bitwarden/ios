import BitwardenSdk
import XCTest

@testable import BitwardenShared

class AuthRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var accountAPIService: APIService!
    var authService: MockAuthService!
    var biometricsRepository: MockBiometricsRepository!
    var client: MockHTTPClient!
    var clientAuth: MockClientAuth!
    var clientCrypto: MockClientCrypto!
    var clientPlatform: MockClientPlatform!
    var environmentService: MockEnvironmentService!
    var keychainService: MockKeychainRepository!
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
        biometricsRepository = MockBiometricsRepository()
        clientCrypto = MockClientCrypto()
        clientPlatform = MockClientPlatform()
        environmentService = MockEnvironmentService()
        keychainService = MockKeychainRepository()
        organizationService = MockOrganizationService()
        stateService = MockStateService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultAuthRepository(
            accountAPIService: accountAPIService,
            authService: authService,
            biometricsRepository: biometricsRepository,
            clientAuth: clientAuth,
            clientCrypto: clientCrypto,
            clientPlatform: clientPlatform,
            environmentService: environmentService,
            keychainService: keychainService,
            organizationService: organizationService,
            stateService: stateService,
            vaultTimeoutService: vaultTimeoutService
        )
    }

    override func tearDown() {
        super.tearDown()

        accountAPIService = nil
        authService = nil
        biometricsRepository = nil
        client = nil
        clientAuth = nil
        clientCrypto = nil
        clientPlatform = nil
        environmentService = nil
        keychainService = nil
        organizationService = nil
        subject = nil
        stateService = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `.clearPins()` clears the user's pins.
    func test_clearPins() async throws {
        stateService.activeAccount = Account.fixture()
        let userId = Account.fixture().profile.userId

        stateService.pinProtectedUserKeyValue[userId] = "123"
        stateService.pinKeyEncryptedUserKeyValue[userId] = "123"
        stateService.accountVolatileData[userId]?.pinProtectedUserKey = "123"

        try await subject.clearPins()
        XCTAssertNil(stateService.pinProtectedUserKeyValue[userId])
        XCTAssertNil(stateService.pinKeyEncryptedUserKeyValue[userId])
        XCTAssertNil(stateService.accountVolatileData[userId]?.pinProtectedUserKey)
    }

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
    func test_allowBioMetricUnlock_biometricsRepositoryError() async throws {
        biometricsRepository.setBiometricUnlockKeyError = BiometricsServiceError.setAuthKeyFailed
        await assertAsyncThrows(error: BiometricsServiceError.setAuthKeyFailed) {
            try await subject.allowBioMetricUnlock(true)
        }
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_cryptoError() async throws {
        biometricsRepository.setBiometricUnlockKeyError = nil
        struct ClientError: Error, Equatable {}
        clientCrypto.getUserEncryptionKeyResult = .failure(ClientError())
        await assertAsyncThrows(error: ClientError()) {
            try await subject.allowBioMetricUnlock(true)
        }
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_true_success() async throws {
        stateService.activeAccount = .fixture()
        biometricsRepository.setBiometricUnlockKeyError = nil
        let key = "userKey"
        clientCrypto.getUserEncryptionKeyResult = .success(key)
        try await subject.allowBioMetricUnlock(true)
        XCTAssertEqual(biometricsRepository.capturedUserAuthKey, key)
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_false_success() async throws {
        stateService.activeAccount = .fixture()
        biometricsRepository.setBiometricUnlockKeyError = nil
        let key = "userKey"
        clientCrypto.getUserEncryptionKeyResult = .success(key)
        try await subject.allowBioMetricUnlock(false)
        XCTAssertNil(biometricsRepository.capturedUserAuthKey)
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_false_success_biometricsRepositoryError() async throws {
        biometricsRepository.setBiometricUnlockKeyError = nil
        clientCrypto.getUserEncryptionKeyResult = .failure(BiometricsServiceError.getAuthKeyFailed)
        try await subject.allowBioMetricUnlock(false)
        XCTAssertNil(biometricsRepository.capturedUserAuthKey)
    }

    /// `getProfilesState()` throws an error when the accounts are nil.
    func test_getProfilesState_empty() async {
        let state = await subject.getProfilesState(isVisible: false, shouldAlwaysHideAddAccount: false)
        XCTAssertEqual(state, .empty(shouldAlwaysHideAddAccount: false))
    }

    /// `getProfilesState()` returns all known accounts.
    func test_getProfilesState_valid() async { // swiftlint:disable:this function_body_length
        stateService.accounts = [
            anneAccount,
            beeAccount,
            claimedAccount,
            empty,
            shortEmail,
            shortName,
        ]

        let accounts = await subject.getProfilesState(isVisible: true, shouldAlwaysHideAddAccount: false).accounts
        XCTAssertEqual(
            accounts.first,
            ProfileSwitcherItem.fixture(
                email: anneAccount.profile.email,
                userId: anneAccount.profile.userId,
                userInitials: "AA"
            )
        )
        XCTAssertEqual(
            accounts[1],
            ProfileSwitcherItem.fixture(
                email: beeAccount.profile.email,
                userId: beeAccount.profile.userId,
                userInitials: "BA"
            )
        )
        XCTAssertEqual(
            accounts[2],
            ProfileSwitcherItem.fixture(
                email: claimedAccount.profile.email,
                userId: claimedAccount.profile.userId,
                userInitials: "CL"
            )
        )
        XCTAssertEqual(
            accounts[3],
            ProfileSwitcherItem.fixture(
                email: "",
                userId: "4",
                userInitials: ".."
            )
        )
        XCTAssertEqual(
            accounts[4],
            ProfileSwitcherItem.fixture(
                email: shortEmail.profile.email,
                userId: shortEmail.profile.userId,
                userInitials: "A"
            )
        )
        XCTAssertEqual(
            accounts[5],
            ProfileSwitcherItem.fixture(
                email: shortName.profile.email,
                userId: shortName.profile.userId,
                userInitials: "AJ"
            )
        )
    }

    /// `getProfilesState()` can return locked accounts correctly.
    func test_getProfilesState_locked() async {
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
        let profiles = await subject.getProfilesState(isVisible: true, shouldAlwaysHideAddAccount: true).accounts
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
    func test_getAccount_empty() async throws {
        stateService.accounts = [
            anneAccount,
        ]

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getAccount()
        }
    }

    /// `getAccount()` returns an account when the active account is valid.
    func test_getAccount_valid() async throws {
        stateService.accounts = [
            anneAccount,
        ]
        stateService.activeAccount = anneAccount

        let active = try await subject.getAccount()
        XCTAssertEqual(
            active,
            anneAccount
        )
    }

    /// `getAccount(for:)` returns an account when there is a match.
    func test_getAccountForProfile_match() async throws {
        stateService.accounts = [
            anneAccount,
        ]
        stateService.activeAccount = anneAccount
        let profile = ProfileSwitcherItem.fixture(
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
        let profile = ProfileSwitcherItem.fixture(
            email: beeAccount.profile.email,
            userId: beeAccount.profile.userId,
            userInitials: "BA"
        )
        await assertAsyncThrows(error: StateServiceError.noAccounts) {
            _ = try await subject.getAccount(for: profile.userId)
        }
    }

    /// `getFingerprintPhrase()` gets the account's fingerprint phrase.
    func test_getFingerprintPhrase() async throws {
        let account = Account.fixture()
        stateService.accounts = [account]
        _ = try await subject.setActiveAccount(userId: account.profile.userId)
        try await stateService.setAccountEncryptionKeys(AccountEncryptionKeys(
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "USER_KEY"
        ))

        let phrase = try await subject.getFingerprintPhrase()
        XCTAssertEqual(clientPlatform.fingerprintMaterialString, account.profile.userId)
        XCTAssertEqual(try clientPlatform.fingerprintResult.get(), phrase)
    }

    /// `getFingerprintPhrase()` throws an error if there is no active account.
    func test_getFingerprintPhrase_throws() async throws {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getFingerprintPhrase()
        }
    }

    /// `isLocked` returns the lock state of an active user.
    func test_isLocked_noUser() async {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.isLocked()
        }
    }

    /// `isLocked` returns the lock state of an active user.
    func test_isLocked_noHistory() async throws {
        stateService.activeAccount = .fixture()
        let isLocked = try await subject.isLocked()
        XCTAssertTrue(isLocked)
    }

    /// `isLocked` returns the lock state of an active user.
    func test_isLocked_value() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        vaultTimeoutService.timeoutStore = [
            "1": false,
        ]

        let isLocked = try await subject.isLocked()
        XCTAssertFalse(isLocked)
    }

    /// `isPinUnlockAvailable` returns the pin unlock availability for the active user.
    func test_isPinUnlockAvailable_noUser() async {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.isPinUnlockAvailable()
        }
    }

    /// `isPinUnlockAvailable` returns the pin unlock availability for the active user.
    func test_isPinUnlockAvailable_noValue() async throws {
        stateService.activeAccount = .fixture()
        let value = try await subject.isPinUnlockAvailable()
        XCTAssertFalse(value)
    }

    /// `isPinUnlockAvailable` returns the pin unlock availability for the active user.
    func test_isPinUnlockAvailable_value() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        stateService.pinProtectedUserKeyValue = [
            active.profile.userId: "123",
        ]
        let value = try await subject.isPinUnlockAvailable()
        XCTAssertTrue(value)
    }

    /// `setVaultTimeout` correctly configures the user's timeout value.
    func test_setVaultTimeout_noUser() async {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.setVaultTimeout(value: .fourHours)
        }
    }

    /// `setVaultTimeout` correctly configures the user's timeout value.
    func test_setVaultTimeout_success() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        try await subject.setVaultTimeout(value: .fourHours)
        XCTAssertEqual(vaultTimeoutService.vaultTimeout[active.profile.userId], .fourHours)
    }

    /// `setVaultTimeout` correctly configures the user's timeout value.
    func test_setVaultTimeout_never_cryptoError() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        clientCrypto.getUserEncryptionKeyResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.setVaultTimeout(value: .never)
        }
    }

    /// `setVaultTimeout` correctly configures the user's timeout value.
    func test_setVaultTimeout_deleteNeverlock_error() async {
        let active = Account.fixture()
        stateService.activeAccount = active
        vaultTimeoutService.vaultTimeout = [
            active.profile.userId: .never,
        ]
        keychainService.deleteResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.setVaultTimeout(value: .fiveMinutes)
        }
    }

    /// `setVaultTimeout` correctly configures the user's timeout value.
    func test_setVaultTimeout_deleteNeverlock_success() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        vaultTimeoutService.vaultTimeout = [
            active.profile.userId: .never,
        ]
        keychainService.mockStorage = [
            keychainService.formattedKey(
                for: KeychainItem.neverLock(
                    userId: active.profile.userId
                )
            ):
                "pasta",
        ]
        keychainService.deleteResult = .success(())
        try await subject.setVaultTimeout(value: .fiveMinutes)
        XCTAssertTrue(keychainService.mockStorage.isEmpty)
    }

    /// `setVaultTimeout` correctly configures the user's timeout value.
    func test_setVaultTimeout_never_success() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        clientCrypto.getUserEncryptionKeyResult = .success("pasta")
        try await subject.setVaultTimeout(value: .never)
        XCTAssertEqual(vaultTimeoutService.vaultTimeout[active.profile.userId], .never)
        XCTAssertEqual(
            keychainService.mockStorage,
            [
                keychainService.formattedKey(
                    for: KeychainItem.neverLock(userId: active.profile.userId)
                ):
                    "pasta",
            ]
        )
    }

    /// `unlockVaultWithNeverlockKey` attempts to unlock the vault using an auth key from the keychain.
    func test_unlockVaultWithNeverlockKey_error() async throws {
        let active = Account.fixture()
        keychainService.mockStorage = [
            keychainService.formattedKey(
                for: KeychainItem.neverLock(
                    userId: active.profile.userId
                )
            ):
                "pasta",
        ]
        stateService.accountEncryptionKeys = [
            active.profile.userId: .init(
                encryptedPrivateKey: "secret",
                encryptedUserKey: "recipe"
            ),
        ]
        clientCrypto.getUserEncryptionKeyResult = .success("sauce")
        clientCrypto.initializeUserCryptoResult = .success(())
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.unlockVaultWithNeverlockKey()
        }
    }

    /// `unlockVaultWithNeverlockKey` attempts to unlock the vault using an auth key from the keychain.
    func test_unlockVaultWithNeverlockKey_success() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        keychainService.mockStorage = [
            keychainService.formattedKey(
                for: KeychainItem.neverLock(
                    userId: active.profile.userId
                )
            ):
                "pasta",
        ]
        stateService.accountEncryptionKeys = [
            active.profile.userId: .init(
                encryptedPrivateKey: "secret",
                encryptedUserKey: "recipe"
            ),
        ]
        clientCrypto.getUserEncryptionKeyResult = .success("sauce")
        clientCrypto.initializeUserCryptoResult = .success(())
        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithNeverlockKey()
        }
    }

    /// `lockVault(userId:)` locks the vault for the specified user id.
    func test_lockVault() async {
        await subject.lockVault(userId: "10")
        XCTAssertEqual(vaultTimeoutService.lockedIds, ["10"])
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

    /// `setPins(_:requirePasswordAfterRestart:)` sets the user's pins.
    func test_setPins() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        clientCrypto.derivePinKeyResult = .success(DerivePinKeyResponse(pinProtectedUserKey: "12", encryptedPin: "34"))

        let userId = account.profile.userId
        try await subject.setPins("123", requirePasswordAfterRestart: true)
        XCTAssertEqual(stateService.pinProtectedUserKeyValue[userId], "12")
        XCTAssertEqual(stateService.pinKeyEncryptedUserKeyValue[userId], "34")
        XCTAssertEqual(stateService.accountVolatileData[
            userId,
            default: AccountVolatileData()
        ].pinProtectedUserKey, "12")
    }

    /// `unlockVaultWithPassword(password:)` unlocks the vault with the user's password.
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
        XCTAssertFalse(biometricsRepository.didConfigureBiometricIntegrity)
    }

    /// `unlockVaultWithPassword(password:)` configures biometric integrity refreshes.
    func test_unlockVault_integrityRefresh() async throws {
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY"
            ),
        ]
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.faceID, enabled: true, hasValidIntegrity: false)
        )

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
        XCTAssertTrue(biometricsRepository.didConfigureBiometricIntegrity)
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
    func test_unlockVaultWithBiometrics_error_biometricsRepository_noKeys() async {
        stateService.activeAccount = .fixture()
        struct KeyError: Error, Equatable {}
        biometricsRepository.getUserAuthKeyResult = .failure(KeyError())
        await assertAsyncThrows(error: KeyError()) {
            _ = try await subject.unlockVaultWithBiometrics()
        }
    }

    /// `unlockVaultWithBiometrics()` throws an error if the vault is unable to be unlocked.
    func test_unlockVaultWithBiometrics_error_stateService_noKey() async {
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys = [:]
        biometricsRepository.getUserAuthKeyResult = .success("UserKey")
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
        biometricsRepository.getUserAuthKeyResult = .success("UserKey")
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
        biometricsRepository.getUserAuthKeyResult = .success("")
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
        biometricsRepository.capturedUserAuthKey = "Value"
        biometricsRepository.setBiometricUnlockKeyError = nil
        let task = Task {
            try await subject.logout()
        }
        waitFor(!vaultTimeoutService.removedIds.isEmpty)
        task.cancel()

        XCTAssertEqual([account.profile.userId], stateService.accountsLoggedOut)
        XCTAssertNil(biometricsRepository.capturedUserAuthKey)
    }

    /// `unlockVault(password:)` throws an error if the vault is unable to be unlocked.
    func test_unlockVault_error() async {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.unlockVaultWithPassword(password: "")
        }
    }

    /// `unlockVaultFromLoginWithDevice()` unlocks the vault using the key returned by an approved auth request.
    func test_unlockVaultFromLoginWithDevice() async throws {
        stateService.activeAccount = Account.fixture()
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(encryptedPrivateKey: "PRIVATE_KEY", encryptedUserKey: "USER_KEY"),
        ]

        try await subject.unlockVaultFromLoginWithDevice(
            privateKey: "AUTH_REQUEST_PRIVATE_KEY",
            key: "KEY",
            masterPasswordHash: "MASTER_PASSWORD_HASH"
        )

        XCTAssertEqual(
            clientCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                privateKey: "PRIVATE_KEY",
                method: .authRequest(requestPrivateKey: "AUTH_REQUEST_PRIVATE_KEY", protectedUserKey: "KEY")
            )
        )
        XCTAssertEqual(stateService.masterPasswordHashes["1"], "MASTER_PASSWORD_HASH")
    }

    /// `unlockVaultWithPIN(_:)` unlocks the vault with the user's PIN.
    func test_unlockVaultWithPIN() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(encryptedPrivateKey: "PRIVATE_KEY", encryptedUserKey: "USER_KEY"),
        ]

        stateService.pinKeyEncryptedUserKeyValue[account.profile.userId] = "123"
        stateService.pinProtectedUserKeyValue[account.profile.userId] = "123"

        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithPIN(pin: "123")
        }

        XCTAssertEqual(
            clientCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                privateKey: "PRIVATE_KEY",
                method: .pin(pin: "123", pinProtectedUserKey: "123")
            )
        )
        XCTAssertEqual(vaultTimeoutService.timeoutStore, ["1": false])
    }

    /// `unlockVaultWithPIN(_:)` throws an error if there's no pin.
    func test_unlockVaultWithPIN_error() async throws {
        stateService.activeAccount = .fixture()
        await assertAsyncThrows(error: StateServiceError.noPinProtectedUserKey) {
            try await subject.unlockVaultWithPIN(pin: "123")
        }
    }

    /// `updateMasterPassword()` rethrows an error if an error occurs.
    func test_updateMasterPassword_error() async throws {
        clientCrypto.updatePasswordResult = .failure(BitwardenTestError.example)
        stateService.activeAccount = .fixture()

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.updateMasterPassword(
                currentPassword: "PASSWORD",
                newPassword: "NEW_PASSWORD",
                passwordHint: "PASSWORD_HINT",
                reason: .weakMasterPasswordOnLogin
            )
        }
    }

    /// `updateMasterPassword()` performs the API request to update the user's password.
    func test_updateMasterPassword_weakMasterPasswordOnLogin() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)
        clientCrypto.updatePasswordResult = .success(
            UpdatePasswordResponse(passwordHash: "NEW_PASSWORD_HASH", newKey: "NEW_KEY")
        )
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "KEY"
        )
        stateService.activeAccount = .fixture()
        stateService.masterPasswordHashes["1"] = "MASTER_PASSWORD_HASH"

        try await subject.updateMasterPassword(
            currentPassword: "PASSWORD",
            newPassword: "NEW_PASSWORD",
            passwordHint: "PASSWORD_HINT",
            reason: .weakMasterPasswordOnLogin
        )

        XCTAssertEqual(clientCrypto.updatePasswordNewPassword, "NEW_PASSWORD")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/accounts/password")

        XCTAssertEqual(stateService.masterPasswordHashes["1"], "NEW_PASSWORD_HASH")
        XCTAssertEqual(
            stateService.accountEncryptionKeys["1"],
            AccountEncryptionKeys(encryptedPrivateKey: "PRIVATE_KEY", encryptedUserKey: "NEW_KEY")
        )
    }
} // swiftlint:disable:this file_length
