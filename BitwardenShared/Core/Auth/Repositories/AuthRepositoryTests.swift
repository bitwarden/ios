import BitwardenSdk
import SwiftUI
import XCTest

@testable import BitwardenShared

class AuthRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var accountAPIService: APIService!
    var authService: MockAuthService!
    var biometricsRepository: MockBiometricsRepository!
    var client: MockHTTPClient!
    var clientService: MockClientService!
    var configService: MockConfigService!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var keyConnectorService: MockKeyConnectorService!
    var keychainService: MockKeychainRepository!
    var organizationService: MockOrganizationService!
    var policyService: MockPolicyService!
    var subject: DefaultAuthRepository!
    var stateService: MockStateService!
    var vaultTimeoutService: MockVaultTimeoutService!
    var trustDeviceService: MockTrustDeviceService!

    let anneAccount = Account
        .fixture(
            profile: .fixture(
                avatarColor: "175DDC",
                email: "Anne.Account@bitwarden.com",
                name: "Anne Account",
                userId: "1"
            )
        )

    let beeAccount = Account
        .fixture(
            profile: .fixture(
                avatarColor: "175DDC",
                email: "bee.account@bitwarden.com",
                userId: "2"
            )
        )

    let claimedAccount = Account
        .fixture(
            profile: .fixture(
                avatarColor: "175DDC",
                email: "claims@bitwarden.com",
                userId: "3"
            )
        )

    let empty = Account
        .fixture(
            profile: .fixture(
                avatarColor: "175DDC",
                email: "",
                userId: "4"
            )
        )

    let shortEmail = Account
        .fixture(
            profile: .fixture(
                avatarColor: "175DDC",
                email: "a@gmail.com",
                userId: "5"
            )
        )

    let shortName = Account
        .fixture(
            profile: .fixture(
                avatarColor: "175DDC",
                email: "aj@gmail.com",
                name: "AJ",
                userId: "6"
            )
        )

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        client = MockHTTPClient()
        clientService = MockClientService()
        accountAPIService = APIService(client: client)
        authService = MockAuthService()
        biometricsRepository = MockBiometricsRepository()
        configService = MockConfigService()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        keyConnectorService = MockKeyConnectorService()
        keychainService = MockKeychainRepository()
        organizationService = MockOrganizationService()
        policyService = MockPolicyService()
        stateService = MockStateService()
        trustDeviceService = MockTrustDeviceService()
        vaultTimeoutService = MockVaultTimeoutService()

        subject = DefaultAuthRepository(
            accountAPIService: accountAPIService,
            authService: authService,
            biometricsRepository: biometricsRepository,
            clientService: clientService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            keychainService: keychainService,
            keyConnectorService: keyConnectorService,
            organizationAPIService: APIService(client: client),
            organizationService: organizationService,
            organizationUserAPIService: APIService(client: client),
            policyService: policyService,
            stateService: stateService,
            trustDeviceService: trustDeviceService,
            vaultTimeoutService: vaultTimeoutService
        )
    }

    override func tearDown() {
        super.tearDown()

        accountAPIService = nil
        authService = nil
        biometricsRepository = nil
        client = nil
        clientService = nil
        configService = nil
        environmentService = nil
        errorReporter = nil
        keychainService = nil
        organizationService = nil
        policyService = nil
        subject = nil
        stateService = nil
        vaultTimeoutService = nil
    }

    // MARK: Tests

    /// `.canBeLocked(userId:)` shoulr reutrn true when user has face ID.
    func test_canBeLocked_hasFaceId() async {
        stateService.userHasMasterPassword["1"] = false
        stateService.pinProtectedUserKeyValue["1"] = "123"
        biometricsRepository.biometricUnlockStatus = .success(.available(.faceID, enabled: true))
        let result = await subject.canBeLocked(userId: "1")
        XCTAssertTrue(result)
    }

    /// `.canBeLocked(userId:)` should true when user has master password.
    func test_canBeLocked_hasMasterPassword() async {
        stateService.userHasMasterPassword["1"] = true
        biometricsRepository.biometricUnlockStatus = .success(.notAvailable)
        let result = await subject.canBeLocked(userId: "1")
        XCTAssertTrue(result)
    }

    /// `.canBeLocked(userId:)` should true when user has PIN.
    func test_canBeLocked_hasPin() async {
        stateService.userHasMasterPassword["1"] = false
        stateService.pinProtectedUserKeyValue["1"] = "123"
        biometricsRepository.biometricUnlockStatus = .success(.available(.faceID, enabled: true))
        let result = await subject.canBeLocked(userId: "1")
        XCTAssertTrue(result)
    }

    /// `.canBeLocked(userId:)` should return false when user has no master password, no face ID, and no PIN.
    func test_canBeLocked_hasNothing() async {
        stateService.userHasMasterPassword["1"] = false
        stateService.pinProtectedUserKeyValue = [:]
        biometricsRepository.biometricUnlockStatus = .success(.notAvailable)
        let result = await subject.canBeLocked(userId: "1")
        XCTAssertFalse(result)
    }

    /// `.canVerifyMasterPassword()`  true when user has master password.
    func test_canVerifyMasterPassword_hasMasterPassword() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.userHasMasterPassword["1"] = true

        let result = try await subject.canVerifyMasterPassword()
        XCTAssertTrue(result)
    }

    /// `.canVerifyMasterPassword()`  false when user doesn't have master password.
    func test_canVerifyMasterPassword_hasNotMasterPassword() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.userHasMasterPassword["1"] = false

        let result = try await subject.canVerifyMasterPassword()
        XCTAssertFalse(result)
    }

    /// `.clearPins()` clears the user's pins.
    func test_clearPins() async throws {
        stateService.activeAccount = Account.fixture()
        let userId = Account.fixture().profile.userId

        stateService.pinProtectedUserKeyValue[userId] = "123"
        stateService.encryptedPinByUserId[userId] = "123"
        stateService.accountVolatileData[userId]?.pinProtectedUserKey = "123"

        try await subject.clearPins()
        XCTAssertNil(stateService.pinProtectedUserKeyValue[userId])
        XCTAssertNil(stateService.encryptedPinByUserId[userId])
        XCTAssertNil(stateService.accountVolatileData[userId]?.pinProtectedUserKey)
    }

    /// `createNewSsoUser()` creates a new account for sso JIT user and trust device.
    func test_createNewSsoUser_remember() async throws {
        let registerTdeInput = RegisterTdeKeyResponse(
            privateKey: "privateKey",
            publicKey: "publicKey",
            adminReset: "adminReset",
            deviceKey: TrustDeviceResponse(
                deviceKey: "deviceKey",
                protectedUserKey: "protectedUserKey",
                protectedDevicePrivateKey: "protectedDevicePrivateKey",
                protectedDevicePublicKey: "protectedDevicePublicKey"
            )
        )
        stateService.activeAccount = Account.fixture()
        client.results = [
            .httpSuccess(testData: .organizationAutoEnrollStatus),
            .httpSuccess(testData: .organizationKeys),
            .httpSuccess(testData: .emptyResponse),
            .httpSuccess(testData: .emptyResponse),
        ]
        clientService.mockAuth.makeRegisterTdeKeysResult = .success(registerTdeInput)
        trustDeviceService.trustDeviceWithExistingKeysResult = .success(())

        try await subject.createNewSsoUser(orgIdentifier: "Bitwarden", rememberDevice: true)

        XCTAssertEqual(trustDeviceService.trustDeviceWithExistingKeysValue, registerTdeInput.deviceKey)
        XCTAssertEqual(clientService.mockAuth.makeRegisterTdeKeysEmail, "user@bitwarden.com")
        XCTAssertEqual(clientService.mockAuth.makeRegisterTdeKeysOrgPublicKey, "MIIBIjAN...2QIDAQAB")
        XCTAssertEqual(clientService.mockAuth.makeRegisterTdeKeysRememberDevice, true)
        XCTAssertEqual(
            stateService.accountEncryptionKeys["1"],
            AccountEncryptionKeys(encryptedPrivateKey: "privateKey", encryptedUserKey: nil)
        )
    }

    /// `createNewSsoUser()` creates a new account for sso JIT user and don't trust device.
    func test_createNewSsoUser_notRemember() async throws {
        let registerTdeInput = RegisterTdeKeyResponse(
            privateKey: "privateKey",
            publicKey: "publicKey",
            adminReset: "adminReset",
            deviceKey: TrustDeviceResponse(
                deviceKey: "deviceKey",
                protectedUserKey: "protectedUserKey",
                protectedDevicePrivateKey: "protectedDevicePrivateKey",
                protectedDevicePublicKey: "protectedDevicePublicKey"
            )
        )
        stateService.activeAccount = Account.fixture()
        client.results = [
            .httpSuccess(testData: .organizationAutoEnrollStatus),
            .httpSuccess(testData: .organizationKeys),
            .httpSuccess(testData: .emptyResponse),
            .httpSuccess(testData: .emptyResponse),
        ]
        clientService.mockAuth.makeRegisterTdeKeysResult = .success(registerTdeInput)

        try await subject.createNewSsoUser(orgIdentifier: "Bitwarden", rememberDevice: false)

        XCTAssertNil(trustDeviceService.trustDeviceWithExistingKeysValue)
        XCTAssertEqual(clientService.mockAuth.makeRegisterTdeKeysOrgPublicKey, "MIIBIjAN...2QIDAQAB")
        XCTAssertEqual(clientService.mockAuth.makeRegisterTdeKeysRememberDevice, false)
        XCTAssertEqual(
            stateService.accountEncryptionKeys["1"],
            AccountEncryptionKeys(encryptedPrivateKey: "privateKey", encryptedUserKey: nil)
        )
    }

    /// `deleteAccount()` deletes the active account and removes it from the state.
    func test_deleteAccount() async throws {
        stateService.accounts = [anneAccount, beeAccount]
        stateService.activeAccount = anneAccount

        client.result = .httpSuccess(testData: APITestData(data: Data()))

        try await subject.deleteAccount(otp: nil, passwordText: "12345")
        let accounts = try await stateService.getAccounts()

        XCTAssertEqual(accounts.count, 1)
        XCTAssertEqual(accounts, [beeAccount])
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertEqual(client.requests[0].url, URL(string: "https://example.com/api/accounts"))
        XCTAssertEqual(vaultTimeoutService.removedIds, [anneAccount.profile.userId])
    }

    /// `existingAccountUserId(email:)` returns the user ID of the existing account with the same
    /// email and base URLs.
    func test_existingAccountUserId() async throws {
        environmentService.baseURL = try XCTUnwrap(EnvironmentURLData.defaultUS.base)
        stateService.activeAccount = .fixture(profile: .fixture(email: "user@bitwarden.com", userId: "1"))
        stateService.environmentURLs["1"] = .defaultUS
        stateService.isAuthenticated["1"] = true
        stateService.userIds = ["1"]

        let userId = await subject.existingAccountUserId(email: "user@bitwarden.com")

        XCTAssertEqual(userId, "1")
    }

    /// `existingAccountUserId(email:)` returns `nil` if getting the environment URLs throws an error.
    func test_existingAccountUserId_getEnvironmentURLsError() async throws {
        environmentService.baseURL = try XCTUnwrap(EnvironmentURLData.defaultUS.base)
        stateService.activeAccount = .fixture(profile: .fixture(email: "user@bitwarden.com", userId: "1"))
        stateService.environmentURLsError = StateServiceError.noAccounts
        stateService.isAuthenticated["1"] = true
        stateService.userIds = ["1"]

        let userId = await subject.existingAccountUserId(email: "user@bitwarden.com")

        XCTAssertNil(userId)
    }

    /// `existingAccountUserId(email:)` logs an error if determining whether an account is authenticated fails.
    func test_existingAccountUserId_isAuthenticatedError() async throws {
        environmentService.baseURL = try XCTUnwrap(EnvironmentURLData.defaultUS.base)
        stateService.activeAccount = .fixture(profile: .fixture(email: "user@bitwarden.com", userId: "1"))
        stateService.environmentURLs["1"] = .defaultUS
        stateService.isAuthenticatedError = BitwardenTestError.example
        stateService.userIds = ["1"]

        let userId = await subject.existingAccountUserId(email: "user@bitwarden.com")

        XCTAssertEqual(userId, "1")
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `existingAccountUserId(email:)` returns `nil` if there's an existing account with the same
    /// email but the base URLs are different.
    func test_existingAccountUserId_matchingAccountDifferentBaseURL() async throws {
        environmentService.baseURL = try XCTUnwrap(EnvironmentURLData.defaultEU.base)
        stateService.activeAccount = .fixture(profile: .fixture(email: "user@bitwarden.com", userId: "1"))
        stateService.environmentURLs["1"] = .defaultUS
        stateService.isAuthenticated["1"] = true
        stateService.userIds = ["1"]

        let userId = await subject.existingAccountUserId(email: "user@bitwarden.com")

        XCTAssertNil(userId)
    }

    /// `existingAccountUserId(email:)` returns the matching user ID with the same base URL, if
    /// there are multiple matches for the user's email.
    func test_existingAccountUserId_multipleMatching() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(email: "user@bitwarden.com", userId: "1"))
        stateService.environmentURLs["1"] = .defaultUS
        stateService.environmentURLs["2"] = .defaultEU
        stateService.isAuthenticated["1"] = true
        stateService.isAuthenticated["2"] = true
        stateService.userIds = ["1", "2"]

        environmentService.baseURL = try XCTUnwrap(EnvironmentURLData.defaultUS.base)
        var userId = await subject.existingAccountUserId(email: "user@bitwarden.com")
        XCTAssertEqual(userId, "1")

        environmentService.baseURL = try XCTUnwrap(EnvironmentURLData.defaultEU.base)
        userId = await subject.existingAccountUserId(email: "user@bitwarden.com")
        XCTAssertEqual(userId, "2")
    }

    /// `existingAccountUserId(email:)` returns `nil` if there's an existing matching account, but
    /// the user isn't authenticated.
    func test_existingAccountUserId_notAuthenticated() async throws {
        environmentService.baseURL = try XCTUnwrap(EnvironmentURLData.defaultUS.base)
        stateService.activeAccount = .fixture(profile: .fixture(email: "user@bitwarden.com", userId: "1"))
        stateService.environmentURLs["1"] = .defaultUS
        stateService.isAuthenticated["1"] = false
        stateService.userIds = ["1"]

        let userId = await subject.existingAccountUserId(email: "user@bitwarden.com")

        XCTAssertNil(userId)
    }

    /// `existingAccountUserId(email:)` returns `nil` if there isn't an account that matches the email.
    func test_existingAccountUserId_noMatchingAccount() async throws {
        let userId = await subject.existingAccountUserId(email: "user@bitwarden.com")

        XCTAssertNil(userId)
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
        clientService.mockCrypto.getUserEncryptionKeyResult = .failure(ClientError())
        await assertAsyncThrows(error: ClientError()) {
            try await subject.allowBioMetricUnlock(true)
        }
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_true_success() async throws {
        stateService.activeAccount = .fixture()
        biometricsRepository.setBiometricUnlockKeyError = nil
        let key = "userKey"
        clientService.mockCrypto.getUserEncryptionKeyResult = .success(key)
        try await subject.allowBioMetricUnlock(true)
        XCTAssertEqual(biometricsRepository.capturedUserAuthKey, key)
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_false_success() async throws {
        stateService.activeAccount = .fixture()
        biometricsRepository.setBiometricUnlockKeyError = nil
        let key = "userKey"
        clientService.mockCrypto.getUserEncryptionKeyResult = .success(key)
        try await subject.allowBioMetricUnlock(false)
        XCTAssertNil(biometricsRepository.capturedUserAuthKey)
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_false_success_biometricsRepositoryError() async throws {
        biometricsRepository.setBiometricUnlockKeyError = nil
        clientService.mockCrypto.getUserEncryptionKeyResult = .failure(BiometricsServiceError.getAuthKeyFailed)
        try await subject.allowBioMetricUnlock(false)
        XCTAssertNil(biometricsRepository.capturedUserAuthKey)
    }

    /// `checkSessionTimeout()` locks an account when the session timeout action is lock.
    func test_checkSessionTimeout_lockAccount() async {
        stateService.accounts = [anneAccount, beeAccount]
        stateService.activeAccount = beeAccount
        stateService.timeoutAction = [anneAccount.profile.userId: .lock]
        vaultTimeoutService.shouldSessionTimeout[anneAccount.profile.userId] = true
        await subject.checkSessionTimeouts(handleActiveUser: nil)
        XCTAssertTrue(vaultTimeoutService.isLocked(userId: anneAccount.profile.userId))
    }

    /// `checkSessionTimeout()` logs out an account when the session timeout action is logout.
    func test_checkSessionTimeout_logoutAccount() async {
        stateService.accounts = [anneAccount, beeAccount]
        stateService.activeAccount = beeAccount
        stateService.timeoutAction = [anneAccount.profile.userId: .logout]
        vaultTimeoutService.shouldSessionTimeout[anneAccount.profile.userId] = true
        await subject.checkSessionTimeouts(handleActiveUser: nil)
        XCTAssertTrue(vaultTimeoutService.removedIds.contains(anneAccount.profile.userId))
        XCTAssertTrue(stateService.accountsLoggedOut.contains(anneAccount.profile.userId))
    }

    /// `checkSessionTimeout()` takes no action to an active  account when the session timeout if the `handleActiveUser`
    /// closure is nil.
    func test_checkSessionTimeout_activeAccount() async {
        stateService.accounts = [anneAccount, beeAccount]
        stateService.activeAccount = beeAccount
        stateService.timeoutAction = [beeAccount.profile.userId: .lock]
        vaultTimeoutService.shouldSessionTimeout[beeAccount.profile.userId] = true
        await subject.checkSessionTimeouts(handleActiveUser: nil)
        XCTAssertFalse(vaultTimeoutService.isLocked(userId: anneAccount.profile.userId))
    }

    /// `checkSessionTimeout()` calls `handleActiveUser` closure when the active account is timed out.
    /// closure is nil.
    func test_checkSessionTimeout_timedOut_activeAccount_handleActiveUser() async {
        stateService.accounts = [anneAccount, beeAccount]
        stateService.activeAccount = beeAccount
        stateService.timeoutAction = [beeAccount.profile.userId: .lock]
        vaultTimeoutService.shouldSessionTimeout[beeAccount.profile.userId] = true
        await subject.checkSessionTimeouts { [beeAccount] userId in
            XCTAssertEqual(userId, beeAccount.profile.userId)
        }
    }

    /// `checkSessionTimeout()` takes no action to an active account is not timed out.
    func test_checkSessionTimeout_activeAccount_handleActiveUser() async {
        stateService.accounts = [anneAccount, beeAccount]
        stateService.activeAccount = beeAccount
        stateService.timeoutAction = [beeAccount.profile.userId: .lock]
        vaultTimeoutService.shouldSessionTimeout[beeAccount.profile.userId] = false
        await subject.checkSessionTimeouts { _ in
            XCTFail(
                "shouldn't be calling `handleActiveUser` closure if the active account is not timed out"
            )
        }
    }

    /// `checkSessionTimeout(handleActiveUser:)` logs an error if one occurs when checking timeouts.
    func test_checkSessionTimeout_error() async {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.accounts = [account]
        vaultTimeoutService.shouldSessionTimeoutError = BitwardenTestError.example

        await subject.checkSessionTimeouts(handleActiveUser: nil)

        waitFor(!errorReporter.errors.isEmpty)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    /// `getProfilesState()` throws an error when the accounts are nil.
    func test_getProfilesState_empty() async {
        let state = await subject.getProfilesState(
            allowLockAndLogout: true,
            isVisible: false,
            shouldAlwaysHideAddAccount: false,
            showPlaceholderToolbarIcon: false
        )
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
        stateService.isAuthenticated = [
            anneAccount.profile.userId: true,
            beeAccount.profile.userId: true,
            claimedAccount.profile.userId: true,
            empty.profile.userId: true,
            shortEmail.profile.userId: true,
            shortName.profile.userId: true,
        ]
        vaultTimeoutService.isClientLocked = [
            anneAccount.profile.userId: true,
            beeAccount.profile.userId: true,
            claimedAccount.profile.userId: true,
            empty.profile.userId: true,
            shortEmail.profile.userId: true,
            shortName.profile.userId: true,
        ]
        let accounts = await subject.getProfilesState(
            allowLockAndLogout: true,
            isVisible: true,
            shouldAlwaysHideAddAccount: false,
            showPlaceholderToolbarIcon: false
        ).accounts
        XCTAssertEqual(
            accounts.first,
            ProfileSwitcherItem.fixture(
                color: Color(hex: anneAccount.profile.avatarColor ?? ""),
                email: anneAccount.profile.email,
                userId: anneAccount.profile.userId,
                userInitials: "AA"
            )
        )
        XCTAssertEqual(
            accounts[1],
            ProfileSwitcherItem.fixture(
                color: Color(hex: beeAccount.profile.avatarColor ?? ""),
                email: beeAccount.profile.email,
                userId: beeAccount.profile.userId,
                userInitials: "BA"
            )
        )
        XCTAssertEqual(
            accounts[2],
            ProfileSwitcherItem.fixture(
                color: Color(hex: claimedAccount.profile.avatarColor ?? ""),
                email: claimedAccount.profile.email,
                userId: claimedAccount.profile.userId,
                userInitials: "CL"
            )
        )
        XCTAssertEqual(
            accounts[3],
            ProfileSwitcherItem.fixture(
                color: Color(hex: empty.profile.avatarColor ?? ""),
                email: "",
                userId: "4",
                userInitials: nil
            )
        )
        XCTAssertEqual(
            accounts[4],
            ProfileSwitcherItem.fixture(
                color: Color(hex: shortEmail.profile.avatarColor ?? ""),
                email: shortEmail.profile.email,
                userId: shortEmail.profile.userId,
                userInitials: "A"
            )
        )
        XCTAssertEqual(
            accounts[5],
            ProfileSwitcherItem.fixture(
                color: Color(hex: shortName.profile.avatarColor ?? ""),
                email: shortName.profile.email,
                userId: shortName.profile.userId,
                userInitials: "AJ"
            )
        )
    }

    /// `getProfilesState()` can return `canBeLocked` accounts correctly.
    func test_getProfilesState_canBeLocked() async { // swiftlint:disable:this function_body_length
        stateService.accounts = [
            anneAccount, // This account does not have a MasterPassword, Face ID, or PIN configured.
            beeAccount, // This account does not have a MasterPassword, Face ID configured, but has a PIN.
        ]

        stateService.isAuthenticated = [
            anneAccount.profile.userId: true,
            beeAccount.profile.userId: true,
        ]
        vaultTimeoutService.isClientLocked = [
            anneAccount.profile.userId: true,
            beeAccount.profile.userId: true,
        ]

        stateService.userHasMasterPassword = [
            anneAccount.profile.userId: false,
            beeAccount.profile.userId: false,
        ]
        stateService.pinProtectedUserKeyValue = [
            beeAccount.profile.userId: "123",
        ]
        let accounts = await subject.getProfilesState(
            allowLockAndLogout: true,
            isVisible: true,
            shouldAlwaysHideAddAccount: false,
            showPlaceholderToolbarIcon: false
        ).accounts

        XCTAssertEqual(
            accounts.first,
            ProfileSwitcherItem.fixture(
                canBeLocked: false,
                color: Color(hex: anneAccount.profile.avatarColor ?? ""),
                email: anneAccount.profile.email,
                userId: anneAccount.profile.userId,
                userInitials: "AA"
            )
        )
        XCTAssertEqual(
            accounts[1],
            ProfileSwitcherItem.fixture(
                color: Color(hex: beeAccount.profile.avatarColor ?? ""),
                email: beeAccount.profile.email,
                userId: beeAccount.profile.userId,
                userInitials: "BA"
            )
        )

        // Test case for an account with no MasterPassword and PIN, but with Face ID enabled.
        stateService.accounts = [
            claimedAccount,
        ]

        stateService.isAuthenticated = [
            claimedAccount.profile.userId: true,
        ]
        vaultTimeoutService.isClientLocked = [
            claimedAccount.profile.userId: true,
        ]
        stateService.userHasMasterPassword = [
            claimedAccount.profile.userId: false,
        ]

        biometricsRepository.biometricUnlockStatus = .success(.available(.faceID, enabled: true))
        let accounts2 = await subject.getProfilesState(
            allowLockAndLogout: true,
            isVisible: true,
            shouldAlwaysHideAddAccount: false,
            showPlaceholderToolbarIcon: false
        ).accounts
        XCTAssertEqual(
            accounts2.first,
            ProfileSwitcherItem.fixture(
                canBeLocked: true,
                color: Color(hex: claimedAccount.profile.avatarColor ?? ""),
                email: claimedAccount.profile.email,
                userId: claimedAccount.profile.userId,
                userInitials: "CL"
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
        vaultTimeoutService.isClientLocked = [
            anneAccount.profile.userId: true,
            beeAccount.profile.userId: false,
            empty.profile.userId: true,
            shortEmail.profile.userId: true,
            shortName.profile.userId: false,
        ]
        let profiles = await subject.getProfilesState(
            allowLockAndLogout: true,
            isVisible: true,
            shouldAlwaysHideAddAccount: true,
            showPlaceholderToolbarIcon: true
        ).accounts
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

    /// `getProfilesState()` can return locked accounts correctly on timeout `.never`.
    func test_getProfilesState_lockedOnNeverLock() async {
        stateService.accounts = [
            anneAccount,
            beeAccount,
            empty,
            shortEmail,
            shortName,
        ]
        vaultTimeoutService.isClientLocked = [
            anneAccount.profile.userId: true,
            beeAccount.profile.userId: true,
            empty.profile.userId: false,
            shortEmail.profile.userId: false,
            shortName.profile.userId: true,
        ]
        stateService.vaultTimeout = [
            anneAccount.profile.userId: .never,
            beeAccount.profile.userId: .never,
            empty.profile.userId: .never,
            shortEmail.profile.userId: .never,
            shortName.profile.userId: .fifteenMinutes,
        ]
        stateService.manuallyLockedAccounts = [
            anneAccount.profile.userId: true,
            beeAccount.profile.userId: false,
            empty.profile.userId: true,
            shortEmail.profile.userId: false,
            shortName.profile.userId: true,
        ]
        let profiles = await subject.getProfilesState(
            allowLockAndLogout: true,
            isVisible: true,
            shouldAlwaysHideAddAccount: true,
            showPlaceholderToolbarIcon: true
        ).accounts
        let unlockedStatuses = profiles.map { profile in
            profile.isUnlocked
        }
        XCTAssertEqual(
            unlockedStatuses,
            [
                false,
                true,
                true,
                true,
                false,
            ]
        )
    }

    /// `getProfilesState()` can return logged out accounts correctly.
    func test_getProfilesState_loggedOut() async {
        stateService.accounts = [
            anneAccount,
            beeAccount,
            empty,
            shortEmail,
            shortName,
        ]
        stateService.isAuthenticated = [
            anneAccount.profile.userId: true,
            beeAccount.profile.userId: false,
            empty.profile.userId: true,
            shortEmail.profile.userId: false,
            shortName.profile.userId: true,
        ]
        vaultTimeoutService.isClientLocked = [
            anneAccount.profile.userId: true,
            beeAccount.profile.userId: false,
            empty.profile.userId: false,
            shortEmail.profile.userId: false,
            shortName.profile.userId: true,
        ]
        let profiles = await subject.getProfilesState(
            allowLockAndLogout: true,
            isVisible: true,
            shouldAlwaysHideAddAccount: true,
            showPlaceholderToolbarIcon: true
        ).accounts
        let loggedOutStatuses = profiles.map(\.isLoggedOut)
        XCTAssertEqual(
            loggedOutStatuses,
            [
                false,
                true,
                false,
                true,
                false,
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
        XCTAssertEqual(clientService.mockPlatform.fingerprintMaterialString, account.profile.userId)
        XCTAssertEqual(try clientService.mockPlatform.fingerprintResult.get(), phrase)
    }

    /// `getFingerprintPhrase()` throws an error if there is no active account.
    func test_getFingerprintPhrase_throws() async throws {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.getFingerprintPhrase()
        }
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns the organization identifier when
    /// the feature flag `.refactorSsoDetailsEndpoint` is off.
    func test_getSingleSignOnOrganizationIdentifier_successFeatureFlagOff() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDetails)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertEqual(orgId, "TeamLivefront")
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns `nil` when email is empty.
    func test_getSingleSignOnOrganizationIdentifier_emptyEmail() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDetails)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "")
        XCTAssertNil(orgId)
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns `nil` when
    /// the feature flag `.refactorSsoDetailsEndpoint` is off and SSO not available in the response.
    func test_getSingleSignOnOrganizationIdentifier_ssoNotAvailableFeatureFlagOff() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDetailsNotAvailable)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertNil(orgId)
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns `nil` when
    /// the feature flag `.refactorSsoDetailsEndpoint` is off and no verified date in the response.
    func test_getSingleSignOnOrganizationIdentifier_noVerifiedDateFeatureFlagOff() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDetailsNoVerifiedDate)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertNil(orgId)
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns `nil` when
    /// the feature flag `.refactorSsoDetailsEndpoint` is off and no organization identifier in the response.
    func test_getSingleSignOnOrganizationIdentifier_noOrgIdFeatureFlagOff() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDetailsNoOrgId)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertNil(orgId)
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns `nil` when
    /// the feature flag `.refactorSsoDetailsEndpoint` is off and organization identifier is empty in the response.
    func test_getSingleSignOnOrganizationIdentifier_orgIdEmptyFeatureFlagOff() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDetailsOrgIdEmpty)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertNil(orgId)
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` throws when calling the API
    /// and the feature flag `.refactorSsoDetailsEndpoint` is off.
    func test_getSingleSignOnOrganizationIdentifier_throwsFeatureFlagOff() async throws {
        client.result = .httpFailure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        }
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns the organization identifier when
    /// the feature flag `.refactorSsoDetailsEndpoint` is on.
    @MainActor
    func test_getSingleSignOnOrganizationIdentifier_successFeatureFlagOn() async throws {
        configService.featureFlagsBool[.refactorSsoDetailsEndpoint] = true
        client.result = .httpSuccess(testData: .singleSignOnDomainsVerified)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertEqual(orgId, "TestID")
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns the first organization identifier when
    /// the feature flag `.refactorSsoDetailsEndpoint` is on and there are multiple results in response.
    @MainActor
    func test_getSingleSignOnOrganizationIdentifier_successInMultipleFeatureFlagOn() async throws {
        configService.featureFlagsBool[.refactorSsoDetailsEndpoint] = true
        client.result = .httpSuccess(testData: .singleSignOnDomainsVerifiedMultiple)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertEqual(orgId, "TestID")
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns `nil` when
    /// the feature flag `.refactorSsoDetailsEndpoint` is on and there is no data.
    @MainActor
    func test_getSingleSignOnOrganizationIdentifier_noDataFeatureFlagOn() async throws {
        configService.featureFlagsBool[.refactorSsoDetailsEndpoint] = true
        client.result = .httpSuccess(testData: .singleSignOnDomainsVerifiedNoData)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertNil(orgId)
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns `nil` when
    /// the feature flag `.refactorSsoDetailsEndpoint` is on and data array is empty.
    @MainActor
    func test_getSingleSignOnOrganizationIdentifier_emptyDataFeatureFlagOn() async throws {
        configService.featureFlagsBool[.refactorSsoDetailsEndpoint] = true
        client.result = .httpSuccess(testData: .singleSignOnDomainsVerifiedEmptyData)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertNil(orgId)
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns `nil` when
    /// the feature flag `.refactorSsoDetailsEndpoint` is on and there is no organization identifier.
    @MainActor
    func test_getSingleSignOnOrganizationIdentifier_noOrgIdFeatureFlagOn() async throws {
        configService.featureFlagsBool[.refactorSsoDetailsEndpoint] = true
        client.result = .httpSuccess(testData: .singleSignOnDomainsVerifiedNoOrgId)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertNil(orgId)
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns `nil` when
    /// the feature flag `.refactorSsoDetailsEndpoint` is on and empty organization identifier.
    @MainActor
    func test_getSingleSignOnOrganizationIdentifier_emptyOrgIdFeatureFlagOn() async throws {
        configService.featureFlagsBool[.refactorSsoDetailsEndpoint] = true
        client.result = .httpSuccess(testData: .singleSignOnDomainsVerifiedEmptyOrgId)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertNil(orgId)
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` throws when calling the API
    /// and the feature flag `.refactorSsoDetailsEndpoint` is on.
    @MainActor
    func test_getSingleSignOnOrganizationIdentifier_throwsFeatureFlagOn() async throws {
        configService.featureFlagsBool[.refactorSsoDetailsEndpoint] = true
        client.result = .httpFailure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        }
    }

    /// `hasMasterPassword` returns if user has masterpassword.
    func test_hasMasterPassword_true_normal_user() async throws {
        stateService.activeAccount = Account.fixture()
        let result = try await subject.hasMasterPassword()
        XCTAssertTrue(result)
    }

    /// `hasMasterPassword` returns if user has masterpassword.
    func test_hasMasterPassword_tde_password() async throws {
        stateService.activeAccount = Account.fixtureWithTDE()
        let result = try await subject.hasMasterPassword()
        XCTAssertTrue(result)
    }

    /// `hasMasterPassword` returns if user has masterpassword.
    func test_hasMasterPassword_tde_no_password() async throws {
        stateService.activeAccount = Account.fixtureWithTdeNoPassword()
        let result = try await subject.hasMasterPassword()
        XCTAssertFalse(result)
    }

    /// `isLocked` returns the lock state of an active user.
    func test_isLocked_noUser() async {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.isLocked()
        }
    }

    /// `isLocked` returns the lock state of an active user.
    func test_isLocked_noHistory() async throws {
        let account: BitwardenShared.Account = .fixture()
        stateService.activeAccount = account
        vaultTimeoutService.isClientLocked[account.profile.userId] = true
        let isLocked = try await subject.isLocked()
        XCTAssertTrue(isLocked)
    }

    /// `isLocked` returns the lock state of an active user.
    func test_isLocked_value() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        vaultTimeoutService.isClientLocked = [
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

    /// `isUserManagedByOrganization` returns false when the feature flag is off.
    func test_isUserManagedByOrganization_false_featureFlagOff() async throws {
        stateService.accounts = [.fixture(profile: .fixture(userId: "1"))]
        try await stateService.setActiveAccount(userId: "1")
        organizationService.fetchAllOrganizationsResult = .success([.fixture(id: "One")])

        let value = try await subject.isUserManagedByOrganization()
        XCTAssertFalse(value)
    }

    /// `isUserManagedByOrganization` returns false when the feature flag is off.
    func test_isUserManagedByOrganization_true_featureFlagOff() async throws {
        stateService.accounts = [.fixture(profile: .fixture(userId: "1"))]
        try await stateService.setActiveAccount(userId: "1")
        organizationService.fetchAllOrganizationsResult =
            .success([.fixture(id: "One", userIsManagedByOrganization: true)])

        let value = try await subject.isUserManagedByOrganization()
        XCTAssertFalse(value)
    }

    /// `isUserManagedByOrganization` returns false when the user isn't managed by an organization.
    @MainActor
    func test_isUserManagedByOrganization_false_featureFlagON() async throws {
        configService.featureFlagsBool[.accountDeprovisioning] = true
        stateService.accounts = [.fixture(profile: .fixture(userId: "1"))]
        try await stateService.setActiveAccount(userId: "1")
        organizationService.fetchAllOrganizationsResult = .success([.fixture(id: "One")])

        let value = try await subject.isUserManagedByOrganization()
        XCTAssertFalse(value)
    }

    /// `isUserManagedByOrganization` returns false when the user doesn't belong to an organization.
    @MainActor
    func test_isUserManagedByOrganization_noOrgs_featureFlagON() async throws {
        configService.featureFlagsBool[.accountDeprovisioning] = true
        stateService.accounts = [.fixture(profile: .fixture(userId: "1"))]
        try await stateService.setActiveAccount(userId: "1")
        organizationService.fetchAllOrganizationsResult = .success([])

        let value = try await subject.isUserManagedByOrganization()
        XCTAssertFalse(value)
    }

    /// `isUserManagedByOrganization` returns true if the user is managed by an organization.
    @MainActor
    func test_isUserManagedByOrganization_true_featureFlagON() async throws {
        configService.featureFlagsBool[.accountDeprovisioning] = true
        stateService.accounts = [.fixture(profile: .fixture(userId: "1"))]
        try await stateService.setActiveAccount(userId: "1")
        organizationService.fetchAllOrganizationsResult =
            .success([.fixture(id: "One", userIsManagedByOrganization: true)])

        let value = try await subject.isUserManagedByOrganization()
        XCTAssertTrue(value)
    }

    /// `isUserManagedByOrganization` returns true if the user is managed by at least one organization.
    @MainActor
    func test_isUserManagedByOrganization_true_multipleOrgs_featureON() async throws {
        configService.featureFlagsBool[.accountDeprovisioning] = true
        stateService.accounts = [.fixture(profile: .fixture(userId: "1"))]
        try await stateService.setActiveAccount(userId: "1")
        organizationService.fetchAllOrganizationsResult =
            .success([
                .fixture(id: "One", userIsManagedByOrganization: true),
                .fixture(id: "Two"),
            ])

        let value = try await subject.isUserManagedByOrganization()
        XCTAssertTrue(value)
    }

    /// `migrateUserToKeyConnector()` migrates the user using the key connector service.
    func test_migrateUserToKeyConnector() async throws {
        keyConnectorService.migrateUserResult = .success(())

        await assertAsyncDoesNotThrow {
            try await subject.migrateUserToKeyConnector(password: "password")
        }
        XCTAssertEqual(keyConnectorService.migrateUserPassword, "password")
    }

    /// `migrateUserToKeyConnector()` throws an error if migrating the user fails.
    func test_migrateUserToKeyConnector_error() async throws {
        keyConnectorService.migrateUserResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.migrateUserToKeyConnector(password: "password")
        }
        XCTAssertEqual(keyConnectorService.migrateUserPassword, "password")
    }

    /// `requestOtp()` makes an API request to request an OTP code for the user.
    func test_requestOtp() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        try await subject.requestOtp()

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/accounts/request-otp")
    }

    /// `setVaultTimeout` correctly configures the user's timeout value.
    func test_sessionTimeoutValue_active_noUser() async {
        vaultTimeoutService.sessionTimeoutValueError = StateServiceError.noActiveAccount
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.sessionTimeoutValue()
        }
    }

    /// `setVaultTimeout` correctly configures the user's timeout value.
    func test_sessionTimeouValue_active_success() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        vaultTimeoutService.vaultTimeout = [
            "1": .fourHours,
        ]
        let value = try await subject.sessionTimeoutValue()
        XCTAssertEqual(value, .fourHours)
    }

    /// `setVaultTimeout` correctly configures the user's timeout value.
    func test_sessionTimeouValue_alt_success() async throws {
        vaultTimeoutService.vaultTimeout = [
            "1": .fourHours,
            "42": .never,
        ]
        let value = try await subject.sessionTimeoutValue(userId: "42")
        XCTAssertEqual(value, .never)
    }

    /// `setMasterPassword()` sets the user's master password, saves their encryption keys and
    /// unlocks the vault.
    func test_setMasterPassword() async throws {
        let account = Account.fixture()
        client.result = .httpSuccess(testData: .emptyResponse)
        clientService.mockCrypto.updatePasswordResult = .success(
            UpdatePasswordResponse(passwordHash: "NEW_PASSWORD_HASH", newKey: "NEW_KEY")
        )
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "KEY"
        )
        stateService.activeAccount = account

        try await subject.setMasterPassword(
            "NEW_PASSWORD",
            masterPasswordHint: "HINT",
            organizationId: "1234",
            organizationIdentifier: "ORG_ID",
            resetPasswordAutoEnroll: false
        )

        XCTAssertEqual(clientService.mockAuth.makeRegisterKeysKdf, account.kdf.sdkKdf)
        XCTAssertEqual(clientService.mockAuth.makeRegisterKeysEmail, account.profile.email)
        XCTAssertEqual(clientService.mockAuth.makeRegisterKeysPassword, "NEW_PASSWORD")

        XCTAssertEqual(clientService.mockAuth.hashPasswordEmail, account.profile.email)
        XCTAssertEqual(clientService.mockAuth.hashPasswordKdfParams, account.kdf.sdkKdf)
        XCTAssertEqual(clientService.mockAuth.hashPasswordPassword, "NEW_PASSWORD")
        XCTAssertEqual(clientService.mockAuth.hashPasswordPurpose, .serverAuthorization)

        let requests = client.requests
        XCTAssertEqual(requests.count, 1)

        XCTAssertEqual(requests[0].url.absoluteString, "https://example.com/api/accounts/set-password")

        XCTAssertEqual(
            stateService.accountEncryptionKeys["1"],
            AccountEncryptionKeys(
                encryptedPrivateKey: "private",
                encryptedUserKey: "encryptedUserKey"
            )
        )
        XCTAssertEqual(stateService.userHasMasterPassword["1"], true)

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                kdfParams: account.kdf.sdkKdf,
                email: account.profile.email,
                privateKey: "private",
                method: .password(password: "NEW_PASSWORD", userKey: "encryptedUserKey")
            )
        )
    }

    /// `setMasterPassword()` throws an error if one occurs.
    func test_setMasterPassword_error() async {
        clientService.mockCrypto.updatePasswordResult = .failure(BitwardenTestError.example)
        stateService.activeAccount = Account.fixtureWithTdeNoPassword()

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.setMasterPassword(
                "PASSWORD",
                masterPasswordHint: "HINT",
                organizationId: "1234",
                organizationIdentifier: "ORG_ID",
                resetPasswordAutoEnroll: false
            )
        }
    }

    /// `setMasterPassword()` sets the user's master password, saves their encryption keys, enrolls
    /// the user in password reset and unlocks the vault.
    func test_setMasterPassword_resetPasswordEnrollment() async throws {
        client.results = [
            .httpSuccess(testData: .emptyResponse),
            .httpSuccess(testData: .organizationKeys),
            .httpSuccess(testData: .emptyResponse),
        ]
        clientService.mockCrypto.updatePasswordResult = .success(
            UpdatePasswordResponse(passwordHash: "NEW_PASSWORD_HASH", newKey: "NEW_KEY")
        )
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "KEY"
        )
        stateService.activeAccount = Account.fixtureWithTdeNoPassword()

        try await subject.setMasterPassword(
            "NEW_PASSWORD",
            masterPasswordHint: "HINT",
            organizationId: "1234",
            organizationIdentifier: "ORG_ID",
            resetPasswordAutoEnroll: true
        )

        XCTAssertEqual(clientService.mockCrypto.updatePasswordNewPassword, "NEW_PASSWORD")
        XCTAssertEqual(
            stateService.accountEncryptionKeys["1"],
            AccountEncryptionKeys(encryptedPrivateKey: "PRIVATE_KEY", encryptedUserKey: "NEW_KEY")
        )
        XCTAssertEqual(stateService.userHasMasterPassword["1"], true)

        XCTAssertEqual(clientService.mockCrypto.enrollAdminPasswordPublicKey, "MIIBIjAN...2QIDAQAB")

        let requests = client.requests
        XCTAssertEqual(requests.count, 3)

        XCTAssertEqual(
            requests[0].url.absoluteString,
            "https://example.com/api/accounts/set-password"
        )
        XCTAssertEqual(
            requests[1].url.absoluteString,
            "https://example.com/api/organizations/1234/public-key"
        )
        XCTAssertEqual(
            requests[2].url.absoluteString,
            "https://example.com/api/organizations/1234/users/1/reset-password-enrollment"
        )
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
        clientService.mockCrypto.getUserEncryptionKeyResult = .failure(BitwardenTestError.example)
        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.setVaultTimeout(value: .never)
        }
    }

    /// `setVaultTimeout` correctly configures the user's timeout value.
    func test_setVaultTimeout_deleteNeverlock_error() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        vaultTimeoutService.vaultTimeout = [
            active.profile.userId: .never,
        ]
        keychainService.deleteResult = .failure(BitwardenTestError.example)
        try await subject.setVaultTimeout(value: .fiveMinutes)
        XCTAssertEqual(vaultTimeoutService.vaultTimeout["1"], .fiveMinutes)
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
        clientService.mockCrypto.getUserEncryptionKeyResult = .success("pasta")
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
        clientService.mockCrypto.getUserEncryptionKeyResult = .success("sauce")
        clientService.mockCrypto.initializeUserCryptoResult = .success(())
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
        clientService.mockCrypto.getUserEncryptionKeyResult = .success("sauce")
        clientService.mockCrypto.initializeUserCryptoResult = .success(())
        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithNeverlockKey()
        }
        XCTAssertFalse(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)
    }

    /// `test_unlockVaultWithDeviceKey` attempts to unlock the vault using the device key from the keychain.
    func test_unlockVaultWithDeviceKey_success() async throws {
        let active = Account.fixtureWithTDE()
        stateService.activeAccount = active
        keychainService.mockStorage = [
            keychainService.formattedKey(
                for: KeychainItem.deviceKey(
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
        clientService.mockCrypto.getUserEncryptionKeyResult = .success("sauce")
        clientService.mockCrypto.initializeUserCryptoResult = .success(())
        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithDeviceKey()
        }
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)
    }

    /// `test_unlockVaultWithDeviceKey` attempts to unlock the vault using the device key from the keychain.
    func test_unlockVaultWithDeviceKey_error() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        keychainService.mockStorage = [
            keychainService.formattedKey(
                for: KeychainItem.deviceKey(
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
        clientService.mockCrypto.getUserEncryptionKeyResult = .success("sauce")
        clientService.mockCrypto.initializeUserCryptoResult = .success(())
        await assertAsyncThrows(error: AuthError.missingUserDecryptionOptions) {
            try await subject.unlockVaultWithDeviceKey()
        }
    }

    /// `lockVault(userId:)` locks the vault for the specified user id.
    func test_lockVault() async {
        await subject.lockVault(userId: "10")
        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "10"))
    }

    /// `lockVault(userId:)` manually locks the vault for the specified user id.
    func test_lockVault_manuallyLocking() async {
        await subject.lockVault(userId: "10", isManuallyLocking: true)
        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "10"))
        XCTAssertEqual(stateService.manuallyLockedAccounts["10"], true)
    }

    /// `lockVault(userId:)` logs error when manually locks the vault for the specified user id.
    func test_lockVault_throwsManuallyLocking() async {
        stateService.activeAccount = nil
        await subject.lockVault(userId: nil, isManuallyLocking: true)
        XCTAssertTrue(stateService.manuallyLockedAccounts.isEmpty)
        XCTAssertEqual(errorReporter.errors.last as? StateServiceError, .noActiveAccount)
    }

    /// `passwordStrength(email:password)` returns the calculated password strength.
    func test_passwordStrength() async throws {
        clientService.mockAuth.passwordStrengthResult = 0
        let weakPasswordStrength = try await subject.passwordStrength(
            email: "user@bitwarden.com",
            password: "password",
            isPreAuth: false
        )
        XCTAssertEqual(weakPasswordStrength, 0)
        XCTAssertEqual(clientService.mockAuth.passwordStrengthEmail, "user@bitwarden.com")
        XCTAssertEqual(clientService.mockAuth.passwordStrengthPassword, "password")
        XCTAssertFalse(clientService.mockAuthIsPreAuth)

        clientService.mockAuth.passwordStrengthResult = 4
        let strongPasswordStrength = try await subject.passwordStrength(
            email: "user@bitwarden.com",
            password: "ghu65zQ0*TjP@ij74g*&FykWss#Kgv8L8j8XmC03",
            isPreAuth: true
        )
        XCTAssertEqual(strongPasswordStrength, 4)
        XCTAssertEqual(clientService.mockAuth.passwordStrengthEmail, "user@bitwarden.com")
        XCTAssertEqual(
            clientService.mockAuth.passwordStrengthPassword,
            "ghu65zQ0*TjP@ij74g*&FykWss#Kgv8L8j8XmC03"
        )

        XCTAssertTrue(clientService.mockAuthIsPreAuth)
        XCTAssertNil(clientService.mockAuthUserId)
    }

    /// `sessionTimeoutAction()` returns the session timeout action for a user.
    func test_sessionTimeoutAction() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.accounts = [.fixture(profile: .fixture(userId: "2"))]
        stateService.timeoutAction["1"] = .lock
        stateService.timeoutAction["2"] = .logout

        var timeoutAction = try await subject.sessionTimeoutAction()
        XCTAssertEqual(timeoutAction, .lock)

        timeoutAction = try await subject.sessionTimeoutAction(userId: "2")
        XCTAssertEqual(timeoutAction, .logout)
    }

    /// `sessionTimeoutAction()` defaults to logout if the user doesn't have a master password and
    /// hasn't enabled pin or biometrics unlock.
    func test_sessionTimeoutAction_noMasterPassword() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.timeoutAction["1"] = .lock
        stateService.userHasMasterPassword["1"] = false

        let timeoutAction = try await subject.sessionTimeoutAction()
        XCTAssertEqual(timeoutAction, .logout)
    }

    /// `sessionTimeoutAction()` allows lock or logout if the user doesn't have a master password
    /// and has biometrics unlock enabled.
    func test_sessionTimeoutAction_noMasterPassword_biometricsEnabled() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.timeoutAction["1"] = .lock
        stateService.userHasMasterPassword["1"] = false
        biometricsRepository.biometricUnlockStatus = .success(
            .available(.faceID, enabled: true)
        )

        var timeoutAction = try await subject.sessionTimeoutAction()
        XCTAssertEqual(timeoutAction, .lock)

        stateService.timeoutAction["1"] = .logout
        timeoutAction = try await subject.sessionTimeoutAction()
        XCTAssertEqual(timeoutAction, .logout)
    }

    /// `sessionTimeoutAction()` allows lock or logout if the user doesn't have a master password
    /// and has pin unlock enabled.
    func test_sessionTimeoutAction_noMasterPassword_pinEnabled() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.pinProtectedUserKeyValue["1"] = "KEY"
        stateService.timeoutAction["1"] = .lock
        stateService.userHasMasterPassword["1"] = false

        var timeoutAction = try await subject.sessionTimeoutAction()
        XCTAssertEqual(timeoutAction, .lock)

        stateService.timeoutAction["1"] = .logout
        timeoutAction = try await subject.sessionTimeoutAction()
        XCTAssertEqual(timeoutAction, .logout)
    }

    /// `setActiveAccount(userId: )` loads the environment URLs for the active account.
    func test_setActiveAccount_loadsEnvironmentURLs() async throws {
        let urls = EnvironmentURLData(base: .example)
        let account = Account.fixture(settings: .fixture(environmentURLs: urls))
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
        clientService.mockCrypto.derivePinKeyResult = .success(
            DerivePinKeyResponse(pinProtectedUserKey: "12", encryptedPin: "34")
        )

        let userId = account.profile.userId
        try await subject.setPins("123", requirePasswordAfterRestart: true)
        XCTAssertEqual(stateService.pinProtectedUserKeyValue[userId], "12")
        XCTAssertEqual(stateService.encryptedPinByUserId[userId], "34")
        XCTAssertEqual(stateService.accountVolatileData[
            userId,
            default: AccountVolatileData()
        ].pinProtectedUserKey, "12")
    }

    /// `.shouldPerformMasterPasswordReprompt(reprompt:)`  when reprompt password
    /// and master password hash exists.
    func test_shouldPerformMasterPasswordReprompt_true() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.userHasMasterPassword["1"] = true

        let result = try await subject.shouldPerformMasterPasswordReprompt(reprompt: .password)
        XCTAssertTrue(result)
    }

    /// `.shouldPerformMasterPasswordReprompt(reprompt:)`  when reprompt password
    /// and master password hash does not exist.
    func test_shouldPerformMasterPasswordReprompt_false_reprompt_password() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.userHasMasterPassword["1"] = false

        let result = try await subject.shouldPerformMasterPasswordReprompt(reprompt: .password)
        XCTAssertFalse(result)
    }

    /// `.shouldPerformMasterPasswordReprompt(reprompt:)`  when reprompt none
    func test_shouldPerformMasterPasswordReprompt_false_reprompt_none() async throws {
        stateService.activeAccount = .fixture()
        stateService.masterPasswordHashes["1"] = "MASTER_PASSWORD_HASH"

        let result = try await subject.shouldPerformMasterPasswordReprompt(reprompt: .none)
        XCTAssertFalse(result)
    }

    /// `unlockVaultWithPassword(password:)` unlocks the vault with the user's password.
    func test_unlockVault() async throws {
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(encryptedPrivateKey: "PRIVATE_KEY", encryptedUserKey: "USER_KEY"),
        ]
        stateService.encryptedPinByUserId["1"] = "ENCRYPTED_PIN"

        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithPassword(password: "password")
        }

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                privateKey: "PRIVATE_KEY",
                method: .password(password: "password", userKey: "USER_KEY")
            )
        )
        XCTAssertFalse(vaultTimeoutService.isLocked(userId: "1"))
        XCTAssertTrue(organizationService.initializeOrganizationCryptoCalled)
        XCTAssertEqual(authService.hashPasswordPassword, "password")
        XCTAssertEqual(stateService.accountVolatileData["1"]?.pinProtectedUserKey, "ENCRYPTED_USER_KEY")
        XCTAssertEqual(stateService.masterPasswordHashes["1"], "hashed")
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)
    }

    /// `unlockVaultWithAuthenticatorVaultKey` throws when it encounters an error trying to unlock
    /// the vault using the authenticator vault key from the keychain when the key is not found.
    func test_unlockVaultWithAuthenticatorVaultKey_error() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        await assertAsyncThrows(error: KeychainServiceError.keyNotFound(
            .authenticatorVaultKey(userId: active.profile.userId))
        ) {
            try await subject.unlockVaultWithAuthenticatorVaultKey(userId: active.profile.userId)
        }
    }

    /// `unlockVaultWithAuthenticatorVaultKey` unlocks the vault using the authenticator vault
    /// key from the keychain.
    func test_unlockVaultWithAuthenticatorVaultKey_success() async throws {
        let active = Account.fixture()
        stateService.activeAccount = active
        keychainService.mockStorage = [
            keychainService.formattedKey(
                for: KeychainItem.authenticatorVaultKey(
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
        clientService.mockCrypto.getUserEncryptionKeyResult = .success("sauce")
        clientService.mockCrypto.initializeUserCryptoResult = .success(())
        try await subject.unlockVaultWithAuthenticatorVaultKey(userId: active.profile.userId)
        XCTAssertFalse(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)
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
        clientService.mockCrypto.initializeUserCryptoResult = .failure(CryptoError())
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
        clientService.mockCrypto.initializeUserCryptoResult = .success(())
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
        clientService.mockCrypto.initializeUserCryptoResult = .success(())
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
        stateService.encryptedPinByUserId["1"] = "ENCRYPTED_PIN"
        clientService.mockCrypto.initializeUserCryptoResult = .success(())

        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithBiometrics()
        }

        XCTAssertEqual(stateService.accountVolatileData["1"]?.pinProtectedUserKey, "ENCRYPTED_USER_KEY")
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)
    }

    /// `unlockVaultWithKeyConnectorKey()` unlocks the user's vault with their key connector key.
    func test_unlockVaultWithKeyConnectorKey() async {
        clientService.mockCrypto.initializeUserCryptoResult = .success(())
        keyConnectorService.getMasterKeyFromKeyConnectorResult = .success("key")
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                encryptedPrivateKey: "private",
                encryptedUserKey: "user"
            ),
        ]
        stateService.activeAccount = .fixture()

        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithKeyConnectorKey(
                keyConnectorURL: URL(string: "https://example.com")!,
                orgIdentifier: "org-id"
            )
        }

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                kdfParams: KdfConfig().sdkKdf,
                email: "user@bitwarden.com",
                privateKey: "private",
                method: .keyConnector(masterKey: "key", userKey: "user")
            )
        )
        XCTAssertFalse(keyConnectorService.convertNewUserToKeyConnectorCalled)
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)
    }

    /// `unlockVaultWithKeyConnectorKey()` converts a new user to use key connector and unlocks the
    /// user's vault with their key connector key.
    func test_unlockVaultWithKeyConnectorKey_newKeyConnectorUser() async {
        clientService.mockCrypto.initializeUserCryptoResult = .success(())
        keyConnectorService.convertNewUserToKeyConnectorHandler = { [weak self] in
            self?.stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
                encryptedPrivateKey: "private",
                encryptedUserKey: "user"
            )
            self?.stateService.getAccountEncryptionKeysError = nil
        }
        keyConnectorService.getMasterKeyFromKeyConnectorResult = .success("key")
        stateService.activeAccount = .fixture()
        stateService.getAccountEncryptionKeysError = StateServiceError.noEncryptedPrivateKey

        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithKeyConnectorKey(
                keyConnectorURL: URL(string: "https://example.com")!,
                orgIdentifier: "org-id"
            )
        }

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                kdfParams: KdfConfig().sdkKdf,
                email: "user@bitwarden.com",
                privateKey: "private",
                method: .keyConnector(masterKey: "key", userKey: "user")
            )
        )
        XCTAssertTrue(keyConnectorService.convertNewUserToKeyConnectorCalled)
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
    }

    /// `unlockVaultWithKeyConnectorKey()` throws an error if the user is missing an encrypted user key.
    func test_unlockVaultWithKeyConnectorKey_missingEncryptedUserKey() async {
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                encryptedPrivateKey: "private",
                encryptedUserKey: nil
            ),
        ]

        await assertAsyncThrows(error: StateServiceError.noEncUserKey) {
            try await subject.unlockVaultWithKeyConnectorKey(
                keyConnectorURL: URL(string: "https://example.com")!,
                orgIdentifier: "org-id"
            )
        }
    }

    /// `unlockVaultWithKeyConnectorKey()` throws an error if there's no active account.
    func test_unlockVaultWithKeyConnectorKey_noActiveAccount() async {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.unlockVaultWithKeyConnectorKey(
                keyConnectorURL: URL(string: "https://example.com")!,
                orgIdentifier: "org-id"
            )
        }
    }

    /// `logout` throws an error with no accounts.
    func test_logout_noAccounts() async {
        stateService.accounts = []
        stateService.activeAccount = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.logout(userInitiated: true)
        }
    }

    /// `logout` throws an error with no active account.
    func test_logout_noActiveAccount() async {
        let account = Account.fixtureAccountLogin()
        stateService.accounts = [account]
        stateService.activeAccount = nil
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            _ = try await subject.logout(userInitiated: true)
        }
    }

    /// `logout` successfully logs out a user when the logout isn't user initiated.
    func test_logout_notUserInitiated() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        try await subject.logout(userInitiated: false)

        XCTAssertEqual([account.profile.userId], stateService.accountsLoggedOut)
        XCTAssertFalse(stateService.logoutAccountUserInitiated)
        XCTAssertEqual(vaultTimeoutService.removedIds, [anneAccount.profile.userId])
    }

    /// `logout` successfully logs out a user.
    func test_logout_success() {
        let account = Account.fixture()
        stateService.accounts = [account]
        stateService.activeAccount = account
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        biometricsRepository.capturedUserAuthKey = "Value"
        biometricsRepository.setBiometricUnlockKeyError = nil
        stateService.pinProtectedUserKeyValue["1"] = "1"
        stateService.encryptedPinByUserId["1"] = "1"
        let task = Task {
            try await subject.logout(userInitiated: true)
        }
        waitFor(!vaultTimeoutService.removedIds.isEmpty)
        task.cancel()

        XCTAssertEqual([account.profile.userId], stateService.accountsLoggedOut)
        XCTAssertNil(biometricsRepository.capturedUserAuthKey)
        XCTAssertEqual(keychainService.deleteItemsForUserIds, ["1"])
        XCTAssertTrue(stateService.logoutAccountUserInitiated)
        XCTAssertEqual(vaultTimeoutService.removedIds, [anneAccount.profile.userId])
        XCTAssertEqual(stateService.pinProtectedUserKeyValue["1"], "1")
        XCTAssertEqual(stateService.encryptedPinByUserId["1"], "1")
    }

    /// `logout` successfully logs out a user clearing pins because of policy Remove unlock with pin being enabled.
    func test_logout_successWhenClearingPins() {
        let account = Account.fixture()
        stateService.accounts = [account]
        stateService.activeAccount = account
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        biometricsRepository.capturedUserAuthKey = "Value"
        biometricsRepository.setBiometricUnlockKeyError = nil
        stateService.pinProtectedUserKeyValue["1"] = "1"
        stateService.encryptedPinByUserId["1"] = "1"
        policyService.policyAppliesToUserResult[.removeUnlockWithPin] = true

        let task = Task {
            try await subject.logout(userInitiated: true)
        }
        waitFor(!vaultTimeoutService.removedIds.isEmpty)
        task.cancel()

        XCTAssertEqual([account.profile.userId], stateService.accountsLoggedOut)
        XCTAssertNil(biometricsRepository.capturedUserAuthKey)
        XCTAssertEqual(keychainService.deleteItemsForUserIds, ["1"])
        XCTAssertTrue(stateService.logoutAccountUserInitiated)
        XCTAssertEqual(vaultTimeoutService.removedIds, [anneAccount.profile.userId])
        XCTAssertNil(stateService.pinProtectedUserKeyValue["1"])
        XCTAssertNil(stateService.encryptedPinByUserId["1"])
    }

    /// `logout` throws when clearing pins and policy Remove unlock with pin being enabled.
    func test_logout_throwsWhenClearingPins() async throws {
        let account = Account.fixture()
        stateService.accounts = [account]
        stateService.activeAccount = nil
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        biometricsRepository.capturedUserAuthKey = "Value"
        biometricsRepository.setBiometricUnlockKeyError = nil
        stateService.pinProtectedUserKeyValue["1"] = "1"
        stateService.encryptedPinByUserId["1"] = "1"
        policyService.policyAppliesToUserResult[.removeUnlockWithPin] = true

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.logout(userInitiated: true)
        }

        XCTAssertEqual([], stateService.accountsLoggedOut)
        XCTAssertNotNil(biometricsRepository.capturedUserAuthKey)
        XCTAssertEqual(keychainService.deleteItemsForUserIds, [])
        XCTAssertFalse(stateService.logoutAccountUserInitiated)
        XCTAssertEqual(vaultTimeoutService.removedIds, [])
        XCTAssertEqual(stateService.pinProtectedUserKeyValue["1"], "1")
        XCTAssertEqual(stateService.encryptedPinByUserId["1"], "1")
    }

    /// `unlockVault(password:)` throws an error if the vault is unable to be unlocked.
    func test_unlockVault_error() async {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.unlockVaultWithPassword(password: "")
        }
    }

    /// `unlockVaultFromLoginWithDevice()` unlocks the vault using the key returned by an approved auth request.
    func test_unlockVaultFromLoginWithDevice_withMasterPasswordHash() async throws {
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
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                privateKey: "PRIVATE_KEY",
                method: .authRequest(
                    requestPrivateKey: "AUTH_REQUEST_PRIVATE_KEY",
                    method: .masterKey(protectedMasterKey: "KEY", authRequestKey: "USER_KEY")
                )
            )
        )
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
    }

    /// `unlockVaultFromLoginWithDevice()` unlocks the vault using the key returned by an approved
    /// auth request without a master password hash.
    func test_unlockVaultFromLoginWithDevice_withoutMasterPasswordHash() async throws {
        stateService.activeAccount = Account.fixture()
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(encryptedPrivateKey: "PRIVATE_KEY", encryptedUserKey: "USER_KEY"),
        ]

        try await subject.unlockVaultFromLoginWithDevice(
            privateKey: "AUTH_REQUEST_PRIVATE_KEY",
            key: "KEY",
            masterPasswordHash: nil
        )

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                privateKey: "PRIVATE_KEY",
                method: .authRequest(
                    requestPrivateKey: "AUTH_REQUEST_PRIVATE_KEY",
                    method: .userKey(protectedUserKey: "KEY")
                )
            )
        )
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)
    }

    /// `unlockVaultWithPIN(_:)` unlocks the vault with the user's PIN.
    func test_unlockVaultWithPIN() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(encryptedPrivateKey: "PRIVATE_KEY", encryptedUserKey: "USER_KEY"),
        ]

        stateService.encryptedPinByUserId[account.profile.userId] = "123"
        stateService.pinProtectedUserKeyValue[account.profile.userId] = "123"

        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithPIN(pin: "123")
        }

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                privateKey: "PRIVATE_KEY",
                method: .pin(pin: "123", pinProtectedUserKey: "123")
            )
        )
        XCTAssertFalse(vaultTimeoutService.isLocked(userId: "1"))
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)
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
        clientService.mockCrypto.updatePasswordResult = .failure(BitwardenTestError.example)
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
        clientService.mockCrypto.updatePasswordResult = .success(
            UpdatePasswordResponse(passwordHash: "NEW_PASSWORD_HASH", newKey: "NEW_KEY")
        )
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "KEY"
        )
        stateService.activeAccount = .fixture()
        stateService.masterPasswordHashes["1"] = "MASTER_PASSWORD_HASH"
        stateService.forcePasswordResetReason["1"] = .adminForcePasswordReset

        try await subject.updateMasterPassword(
            currentPassword: "PASSWORD",
            newPassword: "NEW_PASSWORD",
            passwordHint: "PASSWORD_HINT",
            reason: .weakMasterPasswordOnLogin
        )

        XCTAssertEqual(clientService.mockCrypto.updatePasswordNewPassword, "NEW_PASSWORD")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/accounts/password")

        XCTAssertEqual(stateService.masterPasswordHashes["1"], "NEW_PASSWORD_HASH")
        XCTAssertEqual(
            stateService.accountEncryptionKeys["1"],
            AccountEncryptionKeys(encryptedPrivateKey: "PRIVATE_KEY", encryptedUserKey: "NEW_KEY")
        )
        XCTAssertNil(stateService.forcePasswordResetReason["1"])
    }

    /// `validatePassword(_:)` returns `true` if the master password matches the stored password hash.
    func test_validatePassword() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.masterPasswordHashes["1"] = "wxyz4321"
        clientService.mockAuth.validatePasswordResult = true

        let isValid = try await subject.validatePassword("test1234")

        XCTAssertTrue(isValid)
        XCTAssertEqual(clientService.mockAuth.validatePasswordPassword, "test1234")
        XCTAssertEqual(clientService.mockAuth.validatePasswordPasswordHash, "wxyz4321")
    }

    /// `validatePassword(_:)` validates the password with the user key and sets the master password
    /// hash if successful.
    func test_validatePassword_noPasswordHash() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "KEY"
        )
        clientService.mockAuth.validatePasswordUserKeyResult = .success("MASTER_PASSWORD_HASH")

        let isValid = try await subject.validatePassword("test1234")

        XCTAssertTrue(isValid)
        XCTAssertEqual(clientService.mockAuth.validatePasswordUserKeyPassword, "test1234")
        XCTAssertEqual(clientService.mockAuth.validatePasswordUserKeyEncryptedUserKey, "KEY")
        XCTAssertEqual(stateService.masterPasswordHashes["1"], "MASTER_PASSWORD_HASH")
    }

    /// `validatePassword(_:)` returns `false` if validating the password with the user key fails.
    func test_validatePassword_noPasswordHash_invalidPassword() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "KEY"
        )
        clientService.mockAuth.validatePasswordUserKeyResult = .failure(BitwardenTestError.example)

        let isValid = try await subject.validatePassword("not the password")

        XCTAssertFalse(isValid)
        XCTAssertEqual(clientService.mockAuth.validatePasswordUserKeyPassword, "not the password")
        XCTAssertEqual(clientService.mockAuth.validatePasswordUserKeyEncryptedUserKey, "KEY")
        XCTAssertNil(stateService.masterPasswordHashes["1"])
    }

    /// `validatePassword(_:)` returns `false` if the master password doesn't match the stored password hash.
    func test_validatePassword_notValid() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.masterPasswordHashes["1"] = "wxyz4321"
        clientService.mockAuth.validatePasswordResult = false

        let isValid = try await subject.validatePassword("not the password")

        XCTAssertFalse(isValid)
    }

    /// `validatePin(_:)` returns `true` if the pin is valid.
    func test_validatePin() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.pinProtectedUserKeyValue[account.profile.userId] = "123"

        clientService.mockAuth.validatePinResult = .success(true)

        let isPinValid = try await subject.validatePin(pin: "123")

        XCTAssertTrue(isPinValid)
    }

    /// `validatePin(_:)` returns `false` if the there is no active account.
    func test_validatePin_noActiveAccount() async throws {
        let isPinValid = try await subject.validatePin(pin: "123")

        XCTAssertFalse(isPinValid)
    }

    /// `validatePin(_:)` returns `false` if the there is no pin protected user key.
    func test_validatePin_noPinProtectedUserKey() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        let isPinValid = try await subject.validatePin(pin: "123")

        XCTAssertFalse(isPinValid)
    }

    /// `validatePin(_:)` returns `false` if the pin is not valid.
    func test_validatePin_notValid() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        stateService.pinProtectedUserKeyValue[account.profile.userId] = "123"

        clientService.mockAuth.validatePinResult = .success(false)

        let isPinValid = try await subject.validatePin(pin: "123")

        XCTAssertFalse(isPinValid)
    }

    /// `validatePin(_:)` throws when validating.
    func test_validatePin_throws() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        stateService.pinProtectedUserKeyValue[account.profile.userId] = "123"

        clientService.mockAuth.validatePinResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.validatePin(pin: "123")
        }
    }

    /// `validatePin(_:)` returns `false` if initializing org crypto throws.
    func test_validatePin_initializeOrgCryptoThrows() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account

        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(encryptedPrivateKey: "PRIVATE_KEY", encryptedUserKey: "USER_KEY"),
        ]

        stateService.encryptedPinByUserId[account.profile.userId] = "123"
        stateService.pinProtectedUserKeyValue[account.profile.userId] = "123"

        organizationService.initializeOrganizationCryptoError = BitwardenTestError.example

        let isPinValid = try await subject.validatePin(pin: "123")

        XCTAssertFalse(isPinValid)
    }

    /// `verifyOtp(_:)` makes an API request to verify an OTP code.
    func test_verifyOtp() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        try await subject.verifyOtp("OTP")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/accounts/verify-otp")
    }
} // swiftlint:disable:this file_length
