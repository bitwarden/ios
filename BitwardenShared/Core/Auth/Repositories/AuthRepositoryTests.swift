import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import SwiftUI
import TestHelpers
import XCTest

@testable import BitwardenShared
@testable import BitwardenSharedMocks

@MainActor
class AuthRepositoryTests: BitwardenTestCase { // swiftlint:disable:this type_body_length
    // MARK: Properties

    var accountAPIService: APIService!
    var appContextHelper: MockAppContextHelper!
    var authService: MockAuthService!
    var biometricsRepository: MockBiometricsRepository!
    var changeKdfService: MockChangeKdfService!
    var client: MockHTTPClient!
    var clientService: MockClientService!
    var configService: MockConfigService!
    var environmentService: MockEnvironmentService!
    var errorReporter: MockErrorReporter!
    var flightRecorder: MockFlightRecorder!
    var keyConnectorService: MockKeyConnectorService!
    var keychainService: MockKeychainRepository!
    var organizationService: MockOrganizationService!
    var policyService: MockPolicyService!
    var subject: DefaultAuthRepository!
    var stateService: MockStateService!
    var trustDeviceService: MockTrustDeviceService!
    var userSessionStateService: MockUserSessionStateService!
    var vaultTimeoutService: MockVaultTimeoutService!

    let anneAccount = Account
        .fixture(
            profile: .fixture(
                avatarColor: "175DDC",
                email: "Anne.Account@bitwarden.com",
                name: "Anne Account",
                userId: "1",
            ),
        )

    let beeAccount = Account
        .fixture(
            profile: .fixture(
                avatarColor: "175DDC",
                email: "bee.account@bitwarden.com",
                userId: "2",
            ),
        )

    let claimedAccount = Account
        .fixture(
            profile: .fixture(
                avatarColor: "175DDC",
                email: "claims@bitwarden.com",
                userId: "3",
            ),
        )

    let empty = Account
        .fixture(
            profile: .fixture(
                avatarColor: "175DDC",
                email: "",
                userId: "4",
            ),
        )

    let shortEmail = Account
        .fixture(
            profile: .fixture(
                avatarColor: "175DDC",
                email: "a@gmail.com",
                userId: "5",
            ),
        )

    let shortName = Account
        .fixture(
            profile: .fixture(
                avatarColor: "175DDC",
                email: "aj@gmail.com",
                name: "AJ",
                userId: "6",
            ),
        )

    // MARK: Setup & Teardown

    override func setUp() {
        super.setUp()

        appContextHelper = MockAppContextHelper()
        client = MockHTTPClient()
        clientService = MockClientService()
        accountAPIService = APIService(client: client)
        authService = MockAuthService()
        biometricsRepository = MockBiometricsRepository()
        changeKdfService = MockChangeKdfService()
        configService = MockConfigService()
        environmentService = MockEnvironmentService()
        errorReporter = MockErrorReporter()
        flightRecorder = MockFlightRecorder()
        keyConnectorService = MockKeyConnectorService()
        keychainService = MockKeychainRepository()
        organizationService = MockOrganizationService()
        policyService = MockPolicyService()
        stateService = MockStateService()
        trustDeviceService = MockTrustDeviceService()
        userSessionStateService = MockUserSessionStateService()
        vaultTimeoutService = MockVaultTimeoutService()

        biometricsRepository.getBiometricUnlockStatusReturnValue = .notAvailable
        biometricsRepository.getUserAuthKeyReturnValue = "UserAuthKey"
        userSessionStateService.getVaultTimeoutReturnValue = .fifteenMinutes
        userSessionStateService.getUnsuccessfulUnlockAttemptsReturnValue = 0

        subject = DefaultAuthRepository(
            accountAPIService: accountAPIService,
            appContextHelper: appContextHelper,
            authService: authService,
            biometricsRepository: biometricsRepository,
            changeKdfService: changeKdfService,
            clientService: clientService,
            configService: configService,
            environmentService: environmentService,
            errorReporter: errorReporter,
            flightRecorder: flightRecorder,
            keychainService: keychainService,
            keyConnectorService: keyConnectorService,
            organizationAPIService: APIService(client: client),
            organizationService: organizationService,
            organizationUserAPIService: APIService(client: client),
            policyService: policyService,
            stateService: stateService,
            trustDeviceService: trustDeviceService,
            userSessionStateService: userSessionStateService,
            vaultTimeoutService: vaultTimeoutService,
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()

        accountAPIService = nil
        appContextHelper = nil
        authService = nil
        biometricsRepository = nil
        changeKdfService = nil
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

    /// `.canBeLocked(userId:)` should return true when user has face ID.
    func test_canBeLocked_hasFaceId() async {
        stateService.userHasMasterPassword["1"] = false
        biometricsRepository.getBiometricUnlockStatusReturnValue = .available(.faceID, enabled: true)
        vaultTimeoutService.pinUnlockAvailabilityResult = .success([:])
        let result = await subject.canBeLocked(userId: "1")
        XCTAssertTrue(result)
    }

    /// `.canBeLocked(userId:)` should true when user has master password.
    func test_canBeLocked_hasMasterPassword() async {
        stateService.userHasMasterPassword["1"] = true
        biometricsRepository.getBiometricUnlockStatusReturnValue = .notAvailable
        vaultTimeoutService.pinUnlockAvailabilityResult = .success([:])
        let result = await subject.canBeLocked(userId: "1")
        XCTAssertTrue(result)
    }

    /// `.canBeLocked(userId:)` should true when user has PIN.
    func test_canBeLocked_hasPin() async {
        stateService.userHasMasterPassword["1"] = false
        biometricsRepository.getBiometricUnlockStatusReturnValue = .notAvailable
        vaultTimeoutService.pinUnlockAvailabilityResult = .success(["1": true])
        let result = await subject.canBeLocked(userId: "1")
        XCTAssertTrue(result)
    }

    /// `.canBeLocked(userId:)` should return false when user has no master password, no face ID, and no PIN.
    func test_canBeLocked_hasNothing() async {
        stateService.userHasMasterPassword["1"] = false
        stateService.pinProtectedUserKeyValue = [:]
        biometricsRepository.getBiometricUnlockStatusReturnValue = .notAvailable
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
                protectedDevicePublicKey: "protectedDevicePublicKey",
            ),
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
            AccountEncryptionKeys(
                accountKeys: nil,
                encryptedPrivateKey: "privateKey",
                encryptedUserKey: nil,
            ),
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
                protectedDevicePublicKey: "protectedDevicePublicKey",
            ),
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
            AccountEncryptionKeys(
                accountKeys: nil,
                encryptedPrivateKey: "privateKey",
                encryptedUserKey: nil,
            ),
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
        biometricsRepository.setBiometricUnlockKeyThrowableError = BiometricsServiceError.setAuthKeyFailed
        await assertAsyncThrows(error: BiometricsServiceError.setAuthKeyFailed) {
            try await subject.allowBioMetricUnlock(true)
        }
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_cryptoError() async throws {
        biometricsRepository.setBiometricUnlockKeyThrowableError = nil
        struct ClientError: Error, Equatable {}
        clientService.mockCrypto.getUserEncryptionKeyResult = .failure(ClientError())
        await assertAsyncThrows(error: ClientError()) {
            try await subject.allowBioMetricUnlock(true)
        }
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_true_success() async throws {
        stateService.activeAccount = .fixture()
        biometricsRepository.setBiometricUnlockKeyThrowableError = nil
        let key = "userKey"
        clientService.mockCrypto.getUserEncryptionKeyResult = .success(key)
        try await subject.allowBioMetricUnlock(true)
        XCTAssertEqual(biometricsRepository.setBiometricUnlockKeyReceivedArguments?.authKey, key)
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_false_success() async throws {
        stateService.activeAccount = .fixture()
        biometricsRepository.setBiometricUnlockKeyThrowableError = nil
        let key = "userKey"
        clientService.mockCrypto.getUserEncryptionKeyResult = .success(key)
        try await subject.allowBioMetricUnlock(false)
        XCTAssertNil(biometricsRepository.setBiometricUnlockKeyReceivedArguments?.authKey)
    }

    /// `allowBioMetricUnlock(:)` throws an error if required.
    func test_allowBioMetricUnlock_false_success_biometricsRepositoryError() async throws {
        biometricsRepository.setBiometricUnlockKeyThrowableError = nil
        clientService.mockCrypto.getUserEncryptionKeyResult = .failure(BiometricsServiceError.getAuthKeyFailed)
        try await subject.allowBioMetricUnlock(false)
        XCTAssertNil(biometricsRepository.setBiometricUnlockKeyReceivedArguments?.authKey)
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
        vaultTimeoutService.sessionTimeoutAction[anneAccount.profile.userId] = .logout
        await subject.checkSessionTimeouts(handleActiveUser: nil)
        XCTAssertTrue(vaultTimeoutService.removedIds.contains(anneAccount.profile.userId))
        XCTAssertTrue(stateService.accountsLoggedOut.contains(anneAccount.profile.userId))
    }

    /// `checkSessionTimeout()` takes no action to an active account when the session timeout if the `handleActiveUser`
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
                "shouldn't be calling `handleActiveUser` closure if the active account is not timed out",
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

    /// `checkSessionTimeout()` logs out an inactive account with no unlock method after app restart.
    func test_checkSessionTimeout_noUnlockMethod_logoutAccount() async {
        stateService.accounts = [anneAccount, beeAccount]
        stateService.activeAccount = beeAccount
        stateService.timeoutAction = [anneAccount.profile.userId: .logout]
        // Account is locked (simulating app restart)
        vaultTimeoutService.isClientLocked[anneAccount.profile.userId] = true
        // No time-based timeout
        vaultTimeoutService.shouldSessionTimeout[anneAccount.profile.userId] = false
        // No unlock methods available (no master password, PIN, or biometrics)
        stateService.userHasMasterPassword[anneAccount.profile.userId] = false
        stateService.pinProtectedUserKeyValue[anneAccount.profile.userId] = nil
        biometricsRepository.getBiometricUnlockStatusReturnValue =
            .available(.faceID, enabled: false)
        vaultTimeoutService.sessionTimeoutAction[anneAccount.profile.userId] = .logout
        // Account is authenticated (logged in)
        stateService.isAuthenticated[anneAccount.profile.userId] = true

        await subject.checkSessionTimeouts(handleActiveUser: nil)

        XCTAssertTrue(vaultTimeoutService.removedIds.contains(anneAccount.profile.userId))
        XCTAssertTrue(stateService.accountsLoggedOut.contains(anneAccount.profile.userId))
    }

    /// `checkSessionTimeout()` doesn't attempt to log out an account that is already logged out.
    func test_checkSessionTimeout_noUnlockMethod_alreadyLoggedOut() async {
        stateService.accounts = [anneAccount, beeAccount]
        stateService.activeAccount = beeAccount
        stateService.timeoutAction = [anneAccount.profile.userId: .logout]
        // Account is locked (simulating app restart)
        vaultTimeoutService.isClientLocked[anneAccount.profile.userId] = true
        // No time-based timeout
        vaultTimeoutService.shouldSessionTimeout[anneAccount.profile.userId] = false
        // No unlock methods available (no master password, PIN, or biometrics)
        stateService.userHasMasterPassword[anneAccount.profile.userId] = false
        stateService.pinProtectedUserKeyValue[anneAccount.profile.userId] = nil
        biometricsRepository.getBiometricUnlockStatusReturnValue =
            .available(.faceID, enabled: false)
        // Account is already logged out
        stateService.isAuthenticated[anneAccount.profile.userId] = false

        await subject.checkSessionTimeouts(handleActiveUser: nil)

        // Should NOT attempt to log out an already logged out account
        XCTAssertFalse(vaultTimeoutService.removedIds.contains(anneAccount.profile.userId))
        XCTAssertFalse(stateService.accountsLoggedOut.contains(anneAccount.profile.userId))
    }

    /// `checkSessionTimeout()` doesn't log out an inactive account that is unlocked.
    func test_checkSessionTimeout_noUnlockMethod_accountUnlocked() async {
        stateService.accounts = [anneAccount, beeAccount]
        stateService.activeAccount = beeAccount
        stateService.timeoutAction = [anneAccount.profile.userId: .logout]
        // Account is unlocked
        vaultTimeoutService.isClientLocked[anneAccount.profile.userId] = false
        // No time-based timeout
        vaultTimeoutService.shouldSessionTimeout[anneAccount.profile.userId] = false
        // No unlock methods available
        stateService.userHasMasterPassword[anneAccount.profile.userId] = false
        stateService.pinProtectedUserKeyValue[anneAccount.profile.userId] = nil
        biometricsRepository.getBiometricUnlockStatusReturnValue =
            .available(.faceID, enabled: false)

        await subject.checkSessionTimeouts(handleActiveUser: nil)

        XCTAssertFalse(vaultTimeoutService.removedIds.contains(anneAccount.profile.userId))
        XCTAssertFalse(stateService.accountsLoggedOut.contains(anneAccount.profile.userId))
    }

    /// `checkSessionTimeout()` doesn't log out an inactive locked account that has a master password.
    func test_checkSessionTimeout_noUnlockMethod_hasMasterPassword() async {
        stateService.accounts = [anneAccount, beeAccount]
        stateService.activeAccount = beeAccount
        stateService.timeoutAction = [anneAccount.profile.userId: .logout]
        // Account is locked
        vaultTimeoutService.isClientLocked[anneAccount.profile.userId] = true
        // No time-based timeout
        vaultTimeoutService.shouldSessionTimeout[anneAccount.profile.userId] = false
        // Has master password
        stateService.userHasMasterPassword[anneAccount.profile.userId] = true
        biometricsRepository.getBiometricUnlockStatusReturnValue =
            .available(.faceID, enabled: false)

        await subject.checkSessionTimeouts(handleActiveUser: nil)

        XCTAssertFalse(vaultTimeoutService.removedIds.contains(anneAccount.profile.userId))
        XCTAssertFalse(stateService.accountsLoggedOut.contains(anneAccount.profile.userId))
    }

    /// `checkSessionTimeout()` doesn't log out an inactive locked account that has PIN unlock available.
    func test_checkSessionTimeout_noUnlockMethod_hasPinUnlock() async {
        stateService.accounts = [anneAccount, beeAccount]
        stateService.activeAccount = beeAccount
        stateService.timeoutAction = [anneAccount.profile.userId: .logout]
        // Account is locked
        vaultTimeoutService.isClientLocked[anneAccount.profile.userId] = true
        // No time-based timeout
        vaultTimeoutService.shouldSessionTimeout[anneAccount.profile.userId] = false
        // Has PIN unlock
        stateService.userHasMasterPassword[anneAccount.profile.userId] = false
        stateService.pinProtectedUserKeyValue[anneAccount.profile.userId] = "encrypted-pin-key"
        biometricsRepository.getBiometricUnlockStatusReturnValue =
            .available(.faceID, enabled: false)

        await subject.checkSessionTimeouts(handleActiveUser: nil)

        XCTAssertFalse(vaultTimeoutService.removedIds.contains(anneAccount.profile.userId))
        XCTAssertFalse(stateService.accountsLoggedOut.contains(anneAccount.profile.userId))
    }

    /// `checkSessionTimeout()` doesn't log out an inactive locked account that has biometrics enabled.
    func test_checkSessionTimeout_noUnlockMethod_hasBiometrics() async {
        stateService.accounts = [anneAccount, beeAccount]
        stateService.activeAccount = beeAccount
        stateService.timeoutAction = [anneAccount.profile.userId: .logout]
        // Account is locked
        vaultTimeoutService.isClientLocked[anneAccount.profile.userId] = true
        // No time-based timeout
        vaultTimeoutService.shouldSessionTimeout[anneAccount.profile.userId] = false
        // Has biometrics enabled
        stateService.userHasMasterPassword[anneAccount.profile.userId] = false
        stateService.pinProtectedUserKeyValue[anneAccount.profile.userId] = nil
        biometricsRepository.getBiometricUnlockStatusReturnValue =
            .available(.faceID, enabled: true)

        await subject.checkSessionTimeouts(handleActiveUser: nil)

        XCTAssertFalse(vaultTimeoutService.removedIds.contains(anneAccount.profile.userId))
        XCTAssertFalse(stateService.accountsLoggedOut.contains(anneAccount.profile.userId))
    }

    /// `checkSessionTimeout()` calls handleActiveUser for active account with no unlock method.
    func test_checkSessionTimeout_noUnlockMethod_activeAccount_handleActiveUser() async {
        stateService.accounts = [anneAccount, beeAccount]
        stateService.activeAccount = beeAccount
        stateService.timeoutAction = [beeAccount.profile.userId: .logout]
        // Active account is locked
        vaultTimeoutService.isClientLocked[beeAccount.profile.userId] = true
        // No time-based timeout
        vaultTimeoutService.shouldSessionTimeout[beeAccount.profile.userId] = false
        // No unlock methods available
        stateService.userHasMasterPassword[beeAccount.profile.userId] = false
        stateService.pinProtectedUserKeyValue[beeAccount.profile.userId] = nil
        biometricsRepository.getBiometricUnlockStatusReturnValue =
            .available(.faceID, enabled: false)
        // Account is authenticated (logged in)
        stateService.isAuthenticated[beeAccount.profile.userId] = true

        var handledUserId: String?
        await subject.checkSessionTimeouts { userId in
            handledUserId = userId
        }

        XCTAssertEqual(handledUserId, beeAccount.profile.userId)
    }

    /// `checkSessionTimeout()` passes the `isAppRestart` flag to `VaultTimeoutService` when the
    /// app is restarting.
    func test_checkSessionTimeout_onAppRestart() async {
        stateService.accounts = [anneAccount]
        stateService.activeAccount = anneAccount
        stateService.timeoutAction = [anneAccount.profile.userId: .logout]
        userSessionStateService.getVaultTimeoutReturnValue = .onAppRestart
        vaultTimeoutService.shouldSessionTimeout[anneAccount.profile.userId] = true
        stateService.isAuthenticated[anneAccount.profile.userId] = true

        var handledUserId: String?
        await subject.checkSessionTimeouts(isAppRestart: true) { userId in
            handledUserId = userId
        }

        XCTAssertEqual(handledUserId, anneAccount.profile.userId)
        XCTAssertEqual(vaultTimeoutService.hasPassedSessionTimeoutIsAppRestart, true)
    }

    /// `checkSessionTimeout()` passes the `isAppRestart` flag to `VaultTimeoutService` when the
    /// app isn't restarting.
    func test_checkSessionTimeout_onAppRestart_notRestarting() async {
        stateService.accounts = [anneAccount]
        stateService.activeAccount = anneAccount
        stateService.timeoutAction = [anneAccount.profile.userId: .logout]
        userSessionStateService.getVaultTimeoutReturnValue = .onAppRestart
        vaultTimeoutService.shouldSessionTimeout[anneAccount.profile.userId] = false
        stateService.isAuthenticated[anneAccount.profile.userId] = true

        var handledUserId: String?
        await subject.checkSessionTimeouts(isAppRestart: false) { userId in
            handledUserId = userId
        }

        XCTAssertNil(handledUserId)
        XCTAssertEqual(vaultTimeoutService.hasPassedSessionTimeoutIsAppRestart, false)
    }

    /// `getProfilesState()` throws an error when the accounts are nil.
    func test_getProfilesState_empty() async {
        let state = await subject.getProfilesState(
            allowLockAndLogout: true,
            isVisible: false,
            shouldAlwaysHideAddAccount: false,
            showPlaceholderToolbarIcon: false,
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
            showPlaceholderToolbarIcon: false,
        ).accounts
        XCTAssertEqual(
            accounts.first,
            ProfileSwitcherItem.fixture(
                color: Color(hex: anneAccount.profile.avatarColor ?? ""),
                email: anneAccount.profile.email,
                userId: anneAccount.profile.userId,
                userInitials: "AA",
            ),
        )
        XCTAssertEqual(
            accounts[1],
            ProfileSwitcherItem.fixture(
                color: Color(hex: beeAccount.profile.avatarColor ?? ""),
                email: beeAccount.profile.email,
                userId: beeAccount.profile.userId,
                userInitials: "BA",
            ),
        )
        XCTAssertEqual(
            accounts[2],
            ProfileSwitcherItem.fixture(
                color: Color(hex: claimedAccount.profile.avatarColor ?? ""),
                email: claimedAccount.profile.email,
                userId: claimedAccount.profile.userId,
                userInitials: "CL",
            ),
        )
        XCTAssertEqual(
            accounts[3],
            ProfileSwitcherItem.fixture(
                color: Color(hex: empty.profile.avatarColor ?? ""),
                email: "",
                userId: "4",
                userInitials: nil,
            ),
        )
        XCTAssertEqual(
            accounts[4],
            ProfileSwitcherItem.fixture(
                color: Color(hex: shortEmail.profile.avatarColor ?? ""),
                email: shortEmail.profile.email,
                userId: shortEmail.profile.userId,
                userInitials: "A",
            ),
        )
        XCTAssertEqual(
            accounts[5],
            ProfileSwitcherItem.fixture(
                color: Color(hex: shortName.profile.avatarColor ?? ""),
                email: shortName.profile.email,
                userId: shortName.profile.userId,
                userInitials: "AJ",
            ),
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

        vaultTimeoutService.pinUnlockAvailabilityResult = .success([beeAccount.profile.userId: true])

        let accounts = await subject.getProfilesState(
            allowLockAndLogout: true,
            isVisible: true,
            shouldAlwaysHideAddAccount: false,
            showPlaceholderToolbarIcon: false,
        ).accounts

        XCTAssertEqual(
            accounts.first,
            ProfileSwitcherItem.fixture(
                canBeLocked: false,
                color: Color(hex: anneAccount.profile.avatarColor ?? ""),
                email: anneAccount.profile.email,
                userId: anneAccount.profile.userId,
                userInitials: "AA",
            ),
        )
        XCTAssertEqual(
            accounts[1],
            ProfileSwitcherItem.fixture(
                color: Color(hex: beeAccount.profile.avatarColor ?? ""),
                email: beeAccount.profile.email,
                userId: beeAccount.profile.userId,
                userInitials: "BA",
            ),
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

        biometricsRepository.getBiometricUnlockStatusReturnValue =
            .available(.faceID, enabled: true)
        let accounts2 = await subject.getProfilesState(
            allowLockAndLogout: true,
            isVisible: true,
            shouldAlwaysHideAddAccount: false,
            showPlaceholderToolbarIcon: false,
        ).accounts
        XCTAssertEqual(
            accounts2.first,
            ProfileSwitcherItem.fixture(
                canBeLocked: true,
                color: Color(hex: claimedAccount.profile.avatarColor ?? ""),
                email: claimedAccount.profile.email,
                userId: claimedAccount.profile.userId,
                userInitials: "CL",
            ),
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
            showPlaceholderToolbarIcon: true,
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
            ],
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
        userSessionStateService.getVaultTimeoutClosure = { [weak self] userId in
            guard let self else { return .fourHours }
            switch userId {
            case anneAccount.profile.userId: return .never
            case beeAccount.profile.userId: return .never
            case empty.profile.userId: return .never
            case shortEmail.profile.userId: return .never
            case shortName.profile.userId: return .fifteenMinutes
            default: return .fourHours
            }
        }
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
            showPlaceholderToolbarIcon: true,
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
            ],
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
            showPlaceholderToolbarIcon: true,
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
            ],
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
            anneAccount,
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
            userInitials: "AA",
        )

        let match = try await subject.getAccount(for: profile.userId)
        XCTAssertEqual(
            match,
            anneAccount,
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
            userInitials: "BA",
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
            accountKeys: nil,
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "USER_KEY",
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

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns the organization identifier.
    func test_getSingleSignOnOrganizationIdentifier_success() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDomainsVerified)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertEqual(orgId, "TestID")
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns the first organization identifier when
    /// there are multiple results in response.
    func test_getSingleSignOnOrganizationIdentifier_successInMultiple() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDomainsVerifiedMultiple)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertEqual(orgId, "TestID")
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns `nil` when
    /// there is no data.
    func test_getSingleSignOnOrganizationIdentifier_noData() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDomainsVerifiedNoData)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertNil(orgId)
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns `nil` when
    /// the data array is empty.
    func test_getSingleSignOnOrganizationIdentifier_emptyData() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDomainsVerifiedEmptyData)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertNil(orgId)
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns `nil` when
    /// there is no organization identifier.
    func test_getSingleSignOnOrganizationIdentifier_noOrgId() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDomainsVerifiedNoOrgId)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertNil(orgId)
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` returns `nil` when
    /// there is an empty organization identifier.
    func test_getSingleSignOnOrganizationIdentifier_emptyOrgId() async throws {
        client.result = .httpSuccess(testData: .singleSignOnDomainsVerifiedEmptyOrgId)
        let orgId = try await subject.getSingleSignOnOrganizationIdentifier(email: "foo@bar.com")
        XCTAssertNil(orgId)
    }

    /// `getSingleSignOnOrganizationIdentifier(email:)` throws when calling the API.
    func test_getSingleSignOnOrganizationIdentifier_throws() async throws {
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

    /// `isPinUnlockAvailable` calls the VaultTimeoutService.
    func test_isPinUnlockAvailable() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        vaultTimeoutService.pinUnlockAvailabilityResult = .success(["1": false])
        var value = try await subject.isPinUnlockAvailable(userId: "1")
        XCTAssertFalse(value)

        vaultTimeoutService.pinUnlockAvailabilityResult = .success(["1": true])
        value = try await subject.isPinUnlockAvailable(userId: "1")
        XCTAssertTrue(value)
    }

    /// `isPinUnlockAvailable` throws errors.
    func test_isPinUnlockAvailable_error() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        vaultTimeoutService.pinUnlockAvailabilityResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.isPinUnlockAvailable(userId: "1")
        }
    }

    /// `isUserManagedByOrganization` returns false when the user isn't managed by an organization.
    func test_isUserManagedByOrganization_false() async throws {
        stateService.accounts = [.fixture(profile: .fixture(userId: "1"))]
        try await stateService.setActiveAccount(userId: "1")
        organizationService.fetchAllOrganizationsResult = .success([.fixture(id: "One")])

        let value = try await subject.isUserManagedByOrganization()
        XCTAssertFalse(value)
    }

    /// `isUserManagedByOrganization` returns false when the user doesn't belong to an organization.
    func test_isUserManagedByOrganization_noOrgs() async throws {
        stateService.accounts = [.fixture(profile: .fixture(userId: "1"))]
        try await stateService.setActiveAccount(userId: "1")
        organizationService.fetchAllOrganizationsResult = .success([])

        let value = try await subject.isUserManagedByOrganization()
        XCTAssertFalse(value)
    }

    /// `isUserManagedByOrganization` returns true if the user is managed by an organization.
    func test_isUserManagedByOrganization_true() async throws {
        stateService.accounts = [.fixture(profile: .fixture(userId: "1"))]
        try await stateService.setActiveAccount(userId: "1")
        organizationService.fetchAllOrganizationsResult =
            .success([.fixture(id: "One", userIsManagedByOrganization: true)])

        let value = try await subject.isUserManagedByOrganization()
        XCTAssertTrue(value)
    }

    /// `isUserManagedByOrganization` returns true if the user is managed by at least one organization.
    func test_isUserManagedByOrganization_true_multipleOrgs() async throws {
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

    /// `revokeSelfFromOrganization(organizationId:)` makes an API request to revoke the user's access.
    func test_revokeSelfFromOrganization() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)

        try await subject.revokeSelfFromOrganization(organizationId: "ORG_ID")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .put)
        XCTAssertEqual(
            client.requests[0].url.absoluteString,
            "https://example.com/api/organizations/ORG_ID/users/revoke-self",
        )
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
    func test_setMasterPassword() async throws { // swiftlint:disable:this function_body_length
        let account = Account.fixture(profile: .fixture(
            userDecryptionOptions: UserDecryptionOptions(
                hasMasterPassword: true,
                masterPasswordUnlock: .fixture(),
                keyConnectorOption: nil,
                trustedDeviceOption: nil,
            ),
        ))
        client.result = .httpSuccess(testData: .emptyResponse)
        // Account encryption keys don't exist until after a MP has been set for non-TDE users.
        stateService.accountEncryptionKeys["1"] = nil
        stateService.activeAccount = account

        try await subject.setMasterPassword(
            "NEW_PASSWORD",
            masterPasswordHint: "HINT",
            organizationId: "1234",
            organizationIdentifier: "ORG_ID",
            resetPasswordAutoEnroll: false,
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
                accountKeys: nil,
                encryptedPrivateKey: "private",
                encryptedUserKey: "encryptedUserKey",
            ),
        )
        XCTAssertEqual(stateService.userHasMasterPassword["1"], true)

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: account.kdf.sdkKdf,
                email: account.profile.email,
                accountCryptographicState: .v1(privateKey: "private"),
                method: .masterPasswordUnlock(
                    password: "NEW_PASSWORD",
                    masterPasswordUnlock: MasterPasswordUnlockData(
                        kdf: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                        masterKeyWrappedUserKey: "MASTER_KEY_ENCRYPTED_USER_KEY",
                        salt: "SALT",
                    ),
                ),
            ),
        )
    }

    /// `setMasterPassword()` throws an error if one occurs.
    func test_setMasterPassword_error() async {
        clientService.mockCrypto.makeUpdatePasswordResult = .failure(BitwardenTestError.example)
        stateService.activeAccount = Account.fixtureWithTdeNoPassword()
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            accountKeys: .fixture(),
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "KEY",
        )

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.setMasterPassword(
                "PASSWORD",
                masterPasswordHint: "HINT",
                organizationId: "1234",
                organizationIdentifier: "ORG_ID",
                resetPasswordAutoEnroll: false,
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
        clientService.mockCrypto.makeUpdatePasswordResult = .success(
            UpdatePasswordResponse(passwordHash: "NEW_PASSWORD_HASH", newKey: "NEW_KEY"),
        )
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            accountKeys: .fixture(),
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "KEY",
        )
        stateService.activeAccount = Account.fixtureWithTDE()

        try await subject.setMasterPassword(
            "NEW_PASSWORD",
            masterPasswordHint: "HINT",
            organizationId: "1234",
            organizationIdentifier: "ORG_ID",
            resetPasswordAutoEnroll: true,
        )

        XCTAssertEqual(clientService.mockCrypto.makeUpdatePasswordNewPassword, "NEW_PASSWORD")
        XCTAssertEqual(
            stateService.accountEncryptionKeys["1"],
            AccountEncryptionKeys(
                accountKeys: .fixture(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "NEW_KEY",
            ),
        )
        XCTAssertEqual(stateService.userHasMasterPassword["1"], true)

        XCTAssertEqual(clientService.mockCrypto.enrollAdminPasswordPublicKey, "MIIBIjAN...2QIDAQAB")

        let requests = client.requests
        XCTAssertEqual(requests.count, 3)

        XCTAssertEqual(
            requests[0].url.absoluteString,
            "https://example.com/api/accounts/set-password",
        )
        XCTAssertEqual(
            requests[1].url.absoluteString,
            "https://example.com/api/organizations/1234/public-key",
        )
        XCTAssertEqual(
            requests[2].url.absoluteString,
            "https://example.com/api/organizations/1234/users/1/reset-password-enrollment",
        )
    }

    /// `setMasterPassword()` sets the user's master password, saves their encryption keys and
    /// unlocks the vault.
    func test_setMasterPassword_TDE() async throws {
        var account = Account.fixtureWithTDE()
        account.profile.userDecryptionOptions?.masterPasswordUnlock = .fixture()
        client.result = .httpSuccess(testData: .emptyResponse)
        clientService.mockCrypto.makeUpdatePasswordResult = .success(
            UpdatePasswordResponse(passwordHash: "NEW_PASSWORD_HASH", newKey: "NEW_KEY"),
        )
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            accountKeys: .fixtureFilled(),
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "KEY",
        )
        stateService.activeAccount = account

        try await subject.setMasterPassword(
            "NEW_PASSWORD",
            masterPasswordHint: "HINT",
            organizationId: "1234",
            organizationIdentifier: "ORG_ID",
            resetPasswordAutoEnroll: false,
        )

        XCTAssertEqual(clientService.mockCrypto.makeUpdatePasswordNewPassword, "NEW_PASSWORD")

        let requests = client.requests
        XCTAssertEqual(requests.count, 1)

        XCTAssertEqual(requests[0].url.absoluteString, "https://example.com/api/accounts/set-password")

        XCTAssertEqual(
            stateService.accountEncryptionKeys["1"],
            AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "NEW_KEY",
            ),
        )
        XCTAssertEqual(stateService.userHasMasterPassword["1"], true)

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: account.kdf.sdkKdf,
                email: account.profile.email,
                accountCryptographicState: .v2(
                    privateKey: "WRAPPED_PRIVATE_KEY",
                    signedPublicKey: "SIGNED_PUBLIC_KEY",
                    signingKey: "WRAPPED_SIGNING_KEY",
                    securityState: "SECURITY_STATE",
                ),
                method: .masterPasswordUnlock(
                    password: "NEW_PASSWORD",
                    masterPasswordUnlock: MasterPasswordUnlockData(
                        kdf: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                        masterKeyWrappedUserKey: "MASTER_KEY_ENCRYPTED_USER_KEY",
                        salt: "SALT",
                    ),
                ),
            ),
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
                    userId: active.profile.userId,
                ),
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
                    for: KeychainItem.neverLock(userId: active.profile.userId),
                ):
                    "pasta",
            ],
        )
    }

    /// `unlockVaultWithNeverlockKey` attempts to unlock the vault using an auth key from the keychain.
    func test_unlockVaultWithNeverlockKey_error() async throws {
        let active = Account.fixture()
        keychainService.mockStorage = [
            keychainService.formattedKey(
                for: KeychainItem.neverLock(
                    userId: active.profile.userId,
                ),
            ):
                "pasta",
        ]
        stateService.accountEncryptionKeys = [
            active.profile.userId: .init(
                accountKeys: .fixture(),
                encryptedPrivateKey: "secret",
                encryptedUserKey: "recipe",
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
                    userId: active.profile.userId,
                ),
            ):
                "pasta",
        ]
        stateService.accountEncryptionKeys = [
            active.profile.userId: .init(
                accountKeys: .fixture(),
                encryptedPrivateKey: "secret",
                encryptedUserKey: "recipe",
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
                    userId: active.profile.userId,
                ),
            ):
                "pasta",
        ]
        stateService.accountEncryptionKeys = [
            active.profile.userId: .init(
                accountKeys: .fixture(),
                encryptedPrivateKey: "secret",
                encryptedUserKey: "recipe",
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
                    userId: active.profile.userId,
                ),
            ):
                "pasta",
        ]
        stateService.accountEncryptionKeys = [
            active.profile.userId: .init(
                accountKeys: .fixture(),
                encryptedPrivateKey: "secret",
                encryptedUserKey: "recipe",
            ),
        ]
        clientService.mockCrypto.getUserEncryptionKeyResult = .success("sauce")
        clientService.mockCrypto.initializeUserCryptoResult = .success(())
        await assertAsyncThrows(error: AuthError.missingUserDecryptionOptions) {
            try await subject.unlockVaultWithDeviceKey()
        }
    }

    /// `lockAllVaults(isManuallyLocking:)` locks all available vaults.
    func test_lockAllVaults() async throws {
        stateService.accounts = [
            .fixture(profile: .fixture(userId: "1")),
            .fixture(profile: .fixture(userId: "2")),
            .fixture(profile: .fixture(userId: "3")),
        ]

        try await subject.lockAllVaults(isManuallyLocking: false)

        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "1"))
        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "2"))
        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "3"))
        XCTAssertTrue(stateService.manuallyLockedAccounts.isEmpty)
    }

    /// `lockAllVaults(isManuallyLocking:)` manually locks all available vaults.
    func test_lockAllVaults_manuallyLocking() async throws {
        stateService.accounts = [
            .fixture(profile: .fixture(userId: "1")),
            .fixture(profile: .fixture(userId: "2")),
            .fixture(profile: .fixture(userId: "3")),
        ]

        try await subject.lockAllVaults(isManuallyLocking: true)

        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "1"))
        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "2"))
        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "3"))
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], true)
        XCTAssertEqual(stateService.manuallyLockedAccounts["2"], true)
        XCTAssertEqual(stateService.manuallyLockedAccounts["3"], true)
    }

    /// `lockAllVaults(isManuallyLocking:)` does nothing when there are no accounts.
    func test_lockAllVaults_noAccounts() async throws {
        stateService.accounts = []

        try await subject.lockAllVaults(isManuallyLocking: false)

        XCTAssertTrue(vaultTimeoutService.isClientLocked.isEmpty)
        XCTAssertTrue(stateService.manuallyLockedAccounts.isEmpty)
        XCTAssertTrue(stateService.pendingAppIntentActions.isEmptyOrNil)
    }

    /// `lockAllVaults(isManuallyLocking:)` throws when accounts has no value.
    func test_lockAllVaults_throwsNilAccounts() async throws {
        stateService.accounts = nil

        await assertAsyncThrows(error: StateServiceError.noAccounts) {
            try await subject.lockAllVaults(isManuallyLocking: false)
        }
    }

    /// `lockAllVaults(isManuallyLocking:)` locks all accounts but logs error because it throws at the moment
    /// of updating that the account has been manually locked.
    func test_lockAllVaults_succeedsButLogsErrorWhenUpdatingManuallyLockAccount() async throws {
        stateService.accounts = [
            .fixture(profile: .fixture(userId: "1")),
            .fixture(profile: .fixture(userId: "2")),
            .fixture(profile: .fixture(userId: "3")),
        ]
        stateService.setManuallyLockedAccountError = BitwardenTestError.example

        try await subject.lockAllVaults(isManuallyLocking: true)

        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "1"))
        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "2"))
        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "3"))
        XCTAssertTrue(stateService.manuallyLockedAccounts.isEmpty)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example, .example, .example])
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

    /// `lockVault(userId:)` locks the vault for the specified user id but doesn't update the pending actions
    /// when context is not `.appIntent`.
    func test_lockVault_appContextNotAppIntent() async throws {
        appContextHelper.appContext = .mainApp
        await subject.lockVault(userId: "10")
        XCTAssertTrue(vaultTimeoutService.isLocked(userId: "10"))
        XCTAssertTrue(stateService.pendingAppIntentActions.isEmptyOrNil)
    }

    /// `passwordStrength(email:password)` returns the calculated password strength.
    func test_passwordStrength() async throws {
        clientService.mockAuth.passwordStrengthResult = 0
        let weakPasswordStrength = try await subject.passwordStrength(
            email: "user@bitwarden.com",
            password: "password",
            isPreAuth: false,
        )
        XCTAssertEqual(weakPasswordStrength, 0)
        XCTAssertEqual(clientService.mockAuth.passwordStrengthEmail, "user@bitwarden.com")
        XCTAssertEqual(clientService.mockAuth.passwordStrengthPassword, "password")
        XCTAssertFalse(clientService.mockAuthIsPreAuth)

        clientService.mockAuth.passwordStrengthResult = 4
        let strongPasswordStrength = try await subject.passwordStrength(
            email: "user@bitwarden.com",
            password: "ghu65zQ0*TjP@ij74g*&FykWss#Kgv8L8j8XmC03",
            isPreAuth: true,
        )
        XCTAssertEqual(strongPasswordStrength, 4)
        XCTAssertEqual(clientService.mockAuth.passwordStrengthEmail, "user@bitwarden.com")
        XCTAssertEqual(
            clientService.mockAuth.passwordStrengthPassword,
            "ghu65zQ0*TjP@ij74g*&FykWss#Kgv8L8j8XmC03",
        )

        XCTAssertTrue(clientService.mockAuthIsPreAuth)
        XCTAssertNil(clientService.mockAuthUserId)
    }

    /// `sessionTimeoutAction()` uses the VaultTimeoutService.
    func test_sessionTimeoutAction() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(userId: "1"))
        stateService.accounts = [.fixture(profile: .fixture(userId: "2"))]
        vaultTimeoutService.sessionTimeoutAction["1"] = .lock
        vaultTimeoutService.sessionTimeoutAction["2"] = .logout

        var timeoutAction = try await subject.sessionTimeoutAction()
        XCTAssertEqual(timeoutAction, .lock)

        timeoutAction = try await subject.sessionTimeoutAction(userId: "2")
        XCTAssertEqual(timeoutAction, .logout)
    }

    /// `sessionTimeoutAction()` throws errors.
    func test_sessionTimeoutAction_error() async throws {
        vaultTimeoutService.sessionTimeoutActionError = BitwardenTestError.example

        await assertAsyncThrows(error: BitwardenTestError.example) {
            _ = try await subject.sessionTimeoutAction(userId: "1")
        }
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
        clientService.mockCrypto.enrollPinResult = .success(
            EnrollPinResponse(
                pinProtectedUserKeyEnvelope: "pinProtectedUserKeyEnvelope",
                userKeyEncryptedPin: "userKeyEncryptedPin",
            ),
        )

        try await subject.setPins("123", requirePasswordAfterRestart: true)

        let userId = account.profile.userId
        XCTAssertEqual(stateService.accountVolatileData[
            userId,
            default: AccountVolatileData(),
        ].pinProtectedUserKey, "pinProtectedUserKeyEnvelope")
        XCTAssertEqual(stateService.encryptedPinByUserId[userId], "userKeyEncryptedPin")
        XCTAssertEqual(stateService.pinProtectedUserKeyEnvelopeValue[userId], "pinProtectedUserKeyEnvelope")
        XCTAssertNil(stateService.pinProtectedUserKeyValue[userId])
    }

    /// `setPins(_:requirePasswordAfterRestart:)` throws an error if one occurs.
    func test_setPins_error() async throws {
        clientService.mockCrypto.enrollPinResult = .failure(BitwardenTestError.example)

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.setPins("123", requirePasswordAfterRestart: true)
        }
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
        stateService.activeAccount = .fixture(profile: .fixture(
            userDecryptionOptions: UserDecryptionOptions(
                hasMasterPassword: true,
                masterPasswordUnlock: .fixture(),
                keyConnectorOption: nil,
                trustedDeviceOption: nil,
            ),
        ))
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        ]
        stateService.encryptedPinByUserId["1"] = "ENCRYPTED_PIN"
        stateService.pinUnlockRequiresPasswordAfterRestartValue = true

        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithPassword(password: "password")
        }

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                accountCryptographicState: .v2(
                    privateKey: "WRAPPED_PRIVATE_KEY",
                    signedPublicKey: "SIGNED_PUBLIC_KEY",
                    signingKey: "WRAPPED_SIGNING_KEY",
                    securityState: "SECURITY_STATE",
                ),
                method: .masterPasswordUnlock(
                    password: "password",
                    masterPasswordUnlock: MasterPasswordUnlockData(
                        kdf: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                        masterKeyWrappedUserKey: "MASTER_KEY_ENCRYPTED_USER_KEY",
                        salt: "SALT",
                    ),
                ),
            ),
        )
        XCTAssertFalse(vaultTimeoutService.isLocked(userId: "1"))
        XCTAssertTrue(organizationService.initializeOrganizationCryptoCalled)
        XCTAssertEqual(authService.hashPasswordPassword, "password")
        XCTAssertEqual(stateService.accountVolatileData["1"]?.pinProtectedUserKey, "pinProtectedUserKeyEnvelope")
        XCTAssertEqual(stateService.masterPasswordHashes["1"], "hashed")
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)
    }

    /// `unlockVaultWithPassword(password:)` throws missingMasterPasswordUnlockData error when masterPasswordUnlock nil
    func test_unlockVault_missingMasterPasswordUnlockData() async throws {
        stateService.activeAccount = .fixture(profile: .fixture(
            userDecryptionOptions: UserDecryptionOptions(
                hasMasterPassword: true,
                masterPasswordUnlock: nil,
                keyConnectorOption: nil,
                trustedDeviceOption: nil,
            ),
        ))
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        ]
        stateService.encryptedPinByUserId["1"] = "ENCRYPTED_PIN"

        await assertAsyncThrows(error: AuthError.missingMasterPasswordUnlockData) {
            try await subject.unlockVaultWithPassword(password: "password")
        }
    }

    /// `unlockVaultWithBiometrics()` throws an error if the vault is unable to be unlocked.
    func test_unlockVaultWithBiometrics_error_cryptoFail() async {
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: nil,
                encryptedPrivateKey: "private",
                encryptedUserKey: "user",
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
        biometricsRepository.getUserAuthKeyThrowableError = KeyError()
        await assertAsyncThrows(error: KeyError()) {
            _ = try await subject.unlockVaultWithBiometrics()
        }
    }

    /// `unlockVaultWithBiometrics()` throws an error if the vault is unable to be unlocked.
    func test_unlockVaultWithBiometrics_error_stateService_noKey() async {
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys = [:]
        biometricsRepository.getUserAuthKeyReturnValue = "UserKey"
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
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "Private Key",
                encryptedUserKey: "Encrypted User Key",
            ),
        ]
        biometricsRepository.getUserAuthKeyReturnValue = "UserKey"
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
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "private",
                encryptedUserKey: "user",
            ),
        ]
        stateService.activeAccount = .fixture()
        biometricsRepository.getUserAuthKeyReturnValue = ""
        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithBiometrics()
        }
    }

    /// `unlockVaultWithBiometrics()` throws no error if the vault is able to be unlocked.
    func test_unlockVaultWithBiometrics_success() async {
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "private",
                encryptedUserKey: "user",
            ),
        ]
        stateService.activeAccount = .fixture()
        stateService.encryptedPinByUserId["1"] = "ENCRYPTED_PIN"
        stateService.pinUnlockRequiresPasswordAfterRestartValue = true
        clientService.mockCrypto.initializeUserCryptoResult = .success(())

        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithBiometrics()
        }

        XCTAssertEqual(stateService.accountVolatileData["1"]?.pinProtectedUserKey, "pinProtectedUserKeyEnvelope")
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)
    }

    /// `unlockVaultWithBiometrics()` clears the PIN if enrolling the PIN fails.
    func test_unlockVaultWithBiometrics_enrollPinWithEncryptedPinError() async throws {
        let account = Account.fixture()
        clientService.mockCrypto.enrollPinWithEncryptedPinResult = .failure(BitwardenTestError.example)
        stateService.activeAccount = account
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        ]
        stateService.encryptedPinByUserId[account.profile.userId] = "encryptedPin"
        stateService.pinProtectedUserKeyEnvelopeValue[account.profile.userId] = "pinProtectedUserKeyEnvelope"
        biometricsRepository.getUserAuthKeyReturnValue = "DECRYPTED_USER_KEY"

        try await subject.unlockVaultWithBiometrics()

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: KdfConfig().sdkKdf,
                email: "user@bitwarden.com",
                accountCryptographicState: .v2(
                    privateKey: "WRAPPED_PRIVATE_KEY",
                    signedPublicKey: "SIGNED_PUBLIC_KEY",
                    signingKey: "WRAPPED_SIGNING_KEY",
                    securityState: "SECURITY_STATE",
                ),
                method: .decryptedKey(decryptedUserKey: "DECRYPTED_USER_KEY"),
            ),
        )
        XCTAssertFalse(vaultTimeoutService.isLocked(userId: "1"))
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)

        // Existing PIN is cleared if enrolling the PIN fails.
        XCTAssertEqual(clientService.mockCrypto.enrollPinWithEncryptedPinEncryptedPin, "encryptedPin")
        XCTAssertNil(stateService.accountVolatileData["1"]?.pinProtectedUserKey)
        XCTAssertNil(stateService.encryptedPinByUserId["1"])
        XCTAssertNil(stateService.pinProtectedUserKeyValue["1"])
        XCTAssertEqual(flightRecorder.logMessages, [
            "[Auth] Vault unlocked, method: Decrypted Key (Never Lock/Biometrics)",
            "[Auth] enrollPinWithEncryptedPin failed: example, clearing existing PIN keys",
        ])
    }

    /// `unlockVaultWithKeyConnectorKey()` unlocks the user's vault with their key connector key.
    func test_unlockVaultWithKeyConnectorKey() async {
        clientService.mockCrypto.initializeUserCryptoResult = .success(())
        keyConnectorService.getMasterKeyFromKeyConnectorResult = .success("key")
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: nil,
                encryptedPrivateKey: "private",
                encryptedUserKey: "user",
            ),
        ]
        stateService.activeAccount = .fixture()

        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithKeyConnectorKey(
                keyConnectorURL: URL(string: "https://example.com")!,
                orgIdentifier: "org-id",
            )
        }

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: KdfConfig().sdkKdf,
                email: "user@bitwarden.com",
                accountCryptographicState: .v1(privateKey: "private"),
                method: .keyConnector(masterKey: "key", userKey: "user"),
            ),
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
                accountKeys: nil,
                encryptedPrivateKey: "private",
                encryptedUserKey: "user",
            )
            self?.stateService.getAccountEncryptionKeysError = nil
        }
        keyConnectorService.getMasterKeyFromKeyConnectorResult = .success("key")
        stateService.activeAccount = .fixture()
        stateService.getAccountEncryptionKeysError = StateServiceError.noEncryptedPrivateKey

        await assertAsyncThrows(error: StateServiceError.noEncryptedPrivateKey) {
            try await subject.unlockVaultWithKeyConnectorKey(
                keyConnectorURL: URL(string: "https://example.com")!,
                orgIdentifier: "org-id",
            )
        }

        await assertAsyncDoesNotThrow {
            try await subject.convertNewUserToKeyConnector(
                keyConnectorURL: URL(string: "https://example.com")!,
                orgIdentifier: "org-id",
            )
        }

        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithKeyConnectorKey(
                keyConnectorURL: URL(string: "https://example.com")!,
                orgIdentifier: "org-id",
            )
        }

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: KdfConfig().sdkKdf,
                email: "user@bitwarden.com",
                accountCryptographicState: .v1(privateKey: "private"),
                method: .keyConnector(masterKey: "key", userKey: "user"),
            ),
        )
        XCTAssertTrue(keyConnectorService.convertNewUserToKeyConnectorCalled)
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
    }

    /// `convertNewUserToKeyConnector()` converts a new user to use key connector.
    func test_convertNewUserToKeyconnector() async {
        clientService.mockCrypto.initializeUserCryptoResult = .success(())
        keyConnectorService.convertNewUserToKeyConnectorHandler = { [weak self] in
            self?.stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
                accountKeys: nil,
                encryptedPrivateKey: "private",
                encryptedUserKey: "user",
            )
            self?.stateService.getAccountEncryptionKeysError = nil
        }
        keyConnectorService.getMasterKeyFromKeyConnectorResult = .success("key")
        stateService.activeAccount = .fixture()
        stateService.getAccountEncryptionKeysError = StateServiceError.noEncryptedPrivateKey

        await assertAsyncDoesNotThrow {
            try await subject.convertNewUserToKeyConnector(
                keyConnectorURL: URL(string: "https://example.com")!,
                orgIdentifier: "org-id",
            )
        }
        XCTAssertTrue(keyConnectorService.convertNewUserToKeyConnectorCalled)
        XCTAssertEqual(keyConnectorService.convertNewUserToKeyConnectorOrganizationId,
                       "org-id")
        XCTAssertEqual(keyConnectorService.convertNewUserToKeyConnectorKeyConnectorUrl,
                       URL(string: "https://example.com"))
    }

    /// `unlockVaultWithKeyConnectorKey()` throws an error if the user is missing an encrypted user key.
    func test_unlockVaultWithKeyConnectorKey_missingEncryptedUserKey() async {
        stateService.activeAccount = .fixture()
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: nil,
                encryptedPrivateKey: "private",
                encryptedUserKey: nil,
            ),
        ]

        await assertAsyncThrows(error: StateServiceError.noEncUserKey) {
            try await subject.unlockVaultWithKeyConnectorKey(
                keyConnectorURL: URL(string: "https://example.com")!,
                orgIdentifier: "org-id",
            )
        }
    }

    /// `unlockVaultWithKeyConnectorKey()` throws an error if there's no active account.
    func test_unlockVaultWithKeyConnectorKey_noActiveAccount() async {
        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.unlockVaultWithKeyConnectorKey(
                keyConnectorURL: URL(string: "https://example.com")!,
                orgIdentifier: "org-id",
            )
        }
    }

    // `unlockVaultWithPassword(_:)` unlocks the vault with the user's password and checks if the
    // user's KDF settings need to be updated.
    func test_unlockVaultWithPassword_checksForKdfUpdate() async throws {
        let account = Account.fixture(profile: .fixture(
            kdfIterations: 100_000,
            userDecryptionOptions: UserDecryptionOptions(
                hasMasterPassword: true,
                masterPasswordUnlock: .fixture(iterations: 100_000),
                keyConnectorOption: nil,
                trustedDeviceOption: nil,
            ),
        ))
        configService.featureFlagsBool[.forceUpdateKdfSettings] = false
        changeKdfService.needsKdfUpdateToMinimumsResult = true
        stateService.activeAccount = account
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        ]

        try await subject.unlockVaultWithPassword(password: "password")

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: .pbkdf2(iterations: UInt32(100_000)),
                email: "user@bitwarden.com",
                accountCryptographicState: .v2(
                    privateKey: "WRAPPED_PRIVATE_KEY",
                    signedPublicKey: "SIGNED_PUBLIC_KEY",
                    signingKey: "WRAPPED_SIGNING_KEY",
                    securityState: "SECURITY_STATE",
                ),
                method: .masterPasswordUnlock(
                    password: "password",
                    masterPasswordUnlock: MasterPasswordUnlockData(
                        kdf: .pbkdf2(iterations: 100_000),
                        masterKeyWrappedUserKey: "MASTER_KEY_ENCRYPTED_USER_KEY",
                        salt: "SALT",
                    ),
                ),
            ),
        )
        XCTAssertFalse(vaultTimeoutService.isLocked(userId: "1"))
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)

        XCTAssertTrue(changeKdfService.needsKdfUpdateToMinimumsCalled)
        XCTAssertTrue(changeKdfService.updateKdfToMinimumsCalled)
        XCTAssertEqual(changeKdfService.updateKdfToMinimumsPassword, "password")
    }

    // `unlockVaultWithPassword(_:)` unlocks the vault with the user's password and checks if the
    // user's KDF settings need to be updated. If updating the user's KDF fails, an error is logged
    // but vault unlock still succeeds.
    func test_unlockVaultWithPassword_checksForKdfUpdate_error() async throws { // swiftlint:disable:this function_body_length line_length
        let account = Account.fixture(profile: .fixture(
            kdfIterations: 100_000,
            userDecryptionOptions: UserDecryptionOptions(
                hasMasterPassword: true,
                masterPasswordUnlock: .fixture(iterations: 100_000),
                keyConnectorOption: nil,
                trustedDeviceOption: nil,
            ),
        ))
        configService.featureFlagsBool[.forceUpdateKdfSettings] = false
        changeKdfService.needsKdfUpdateToMinimumsResult = true
        changeKdfService.updateKdfToMinimumsResult = .failure(BitwardenTestError.example)
        stateService.activeAccount = account
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        ]

        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithPassword(password: "password")
        }

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: .pbkdf2(iterations: UInt32(100_000)),
                email: "user@bitwarden.com",
                accountCryptographicState: .v2(
                    privateKey: "WRAPPED_PRIVATE_KEY",
                    signedPublicKey: "SIGNED_PUBLIC_KEY",
                    signingKey: "WRAPPED_SIGNING_KEY",
                    securityState: "SECURITY_STATE",
                ),
                method: .masterPasswordUnlock(
                    password: "password",
                    masterPasswordUnlock: MasterPasswordUnlockData(
                        kdf: .pbkdf2(iterations: 100_000),
                        masterKeyWrappedUserKey: "MASTER_KEY_ENCRYPTED_USER_KEY",
                        salt: "SALT",
                    ),
                ),
            ),
        )
        XCTAssertFalse(vaultTimeoutService.isLocked(userId: "1"))
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)

        XCTAssertTrue(changeKdfService.needsKdfUpdateToMinimumsCalled)
        XCTAssertTrue(changeKdfService.updateKdfToMinimumsCalled)
        XCTAssertEqual(errorReporter.errors as? [BitwardenTestError], [.example])
    }

    // `unlockVaultWithPassword(_:)` unlocks the vault with the user's password using the master
    // password unlock data.
    func test_unlockVaultWithPassword_masterPasswordUnlockData() async throws {
        let account = Account.fixture(profile: .fixture(
            userDecryptionOptions: UserDecryptionOptions(
                hasMasterPassword: true,
                masterPasswordUnlock: .fixture(),
                keyConnectorOption: nil,
                trustedDeviceOption: nil,
            ),
        ))
        stateService.activeAccount = account
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        ]

        await assertAsyncDoesNotThrow {
            try await subject.unlockVaultWithPassword(password: "password")
        }

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: .pbkdf2(iterations: UInt32(600_000)),
                email: "user@bitwarden.com",
                accountCryptographicState: .v2(
                    privateKey: "WRAPPED_PRIVATE_KEY",
                    signedPublicKey: "SIGNED_PUBLIC_KEY",
                    signingKey: "WRAPPED_SIGNING_KEY",
                    securityState: "SECURITY_STATE",
                ),
                method: .masterPasswordUnlock(
                    password: "password",
                    masterPasswordUnlock: MasterPasswordUnlockData(
                        kdf: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                        masterKeyWrappedUserKey: "MASTER_KEY_ENCRYPTED_USER_KEY",
                        salt: "SALT",
                    ),
                ),
            ),
        )
        XCTAssertFalse(vaultTimeoutService.isLocked(userId: "1"))
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)
        XCTAssertEqual(stateService.masterPasswordHashes["1"], "hashed")

        XCTAssertTrue(changeKdfService.needsKdfUpdateToMinimumsCalled)
        XCTAssertFalse(changeKdfService.updateKdfToMinimumsCalled)
        XCTAssertTrue(errorReporter.errors.isEmpty)
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
    func test_logout_success() async throws {
        let account = Account.fixture()
        stateService.accounts = [account]
        stateService.activeAccount = account
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        biometricsRepository.setBiometricUnlockKeyThrowableError = nil
        stateService.pinProtectedUserKeyValue["1"] = "1"
        stateService.encryptedPinByUserId["1"] = "1"
        stateService.syncToAuthenticatorByUserId["1"] = true

        try await subject.logout(userInitiated: true)

        XCTAssertEqual([account.profile.userId], stateService.accountsLoggedOut)
        let setArguments = biometricsRepository.setBiometricUnlockKeyReceivedArguments
        XCTAssertEqual(setArguments?.userId, "1")
        XCTAssertNil(setArguments?.authKey)
        XCTAssertEqual(keychainService.deleteItemsForUserIds, ["1"])
        XCTAssertTrue(stateService.logoutAccountUserInitiated)
        XCTAssertEqual(vaultTimeoutService.removedIds, [anneAccount.profile.userId])
        XCTAssertEqual(stateService.pinProtectedUserKeyValue["1"], "1")
        XCTAssertEqual(stateService.encryptedPinByUserId["1"], "1")
        XCTAssertEqual(stateService.syncToAuthenticatorByUserId["1"], false)
    }

    /// `logout` successfully logs out a user clearing pins because of policy Remove unlock with pin being enabled.
    func test_logout_successWhenClearingPins() async throws {
        let account = Account.fixture()
        stateService.accounts = [account]
        stateService.activeAccount = account
        vaultTimeoutService.isClientLocked[account.profile.userId] = false
        biometricsRepository.setBiometricUnlockKeyThrowableError = nil
        stateService.pinProtectedUserKeyValue["1"] = "1"
        stateService.encryptedPinByUserId["1"] = "1"
        policyService.policyAppliesToUserResult[.removeUnlockWithPin] = true

        try await subject.logout(userInitiated: true)

        XCTAssertEqual([account.profile.userId], stateService.accountsLoggedOut)
        let setArguments = biometricsRepository.setBiometricUnlockKeyReceivedArguments
        XCTAssertEqual(setArguments?.userId, "1")
        XCTAssertNil(setArguments?.authKey)
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
        biometricsRepository.setBiometricUnlockKeyThrowableError = nil
        stateService.pinProtectedUserKeyValue["1"] = "1"
        stateService.encryptedPinByUserId["1"] = "1"
        policyService.policyAppliesToUserResult[.removeUnlockWithPin] = true

        await assertAsyncThrows(error: StateServiceError.noActiveAccount) {
            try await subject.logout(userInitiated: true)
        }

        XCTAssertEqual([], stateService.accountsLoggedOut)
        XCTAssertFalse(biometricsRepository.setBiometricUnlockKeyCalled)
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
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        ]

        try await subject.unlockVaultFromLoginWithDevice(
            privateKey: "AUTH_REQUEST_PRIVATE_KEY",
            key: "KEY",
            masterPasswordHash: "MASTER_PASSWORD_HASH",
        )

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                accountCryptographicState: .v2(
                    privateKey: "WRAPPED_PRIVATE_KEY",
                    signedPublicKey: "SIGNED_PUBLIC_KEY",
                    signingKey: "WRAPPED_SIGNING_KEY",
                    securityState: "SECURITY_STATE",
                ),
                method: .authRequest(
                    requestPrivateKey: "AUTH_REQUEST_PRIVATE_KEY",
                    method: .masterKey(protectedMasterKey: "KEY", authRequestKey: "USER_KEY"),
                ),
            ),
        )
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
    }

    /// `unlockVaultFromLoginWithDevice()` unlocks the vault using the key returned by an approved
    /// auth request without a master password hash.
    func test_unlockVaultFromLoginWithDevice_withoutMasterPasswordHash() async throws {
        stateService.activeAccount = Account.fixture()
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        ]

        try await subject.unlockVaultFromLoginWithDevice(
            privateKey: "AUTH_REQUEST_PRIVATE_KEY",
            key: "KEY",
            masterPasswordHash: nil,
        )

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                accountCryptographicState: .v2(
                    privateKey: "WRAPPED_PRIVATE_KEY",
                    signedPublicKey: "SIGNED_PUBLIC_KEY",
                    signingKey: "WRAPPED_SIGNING_KEY",
                    securityState: "SECURITY_STATE",
                ),
                method: .authRequest(
                    requestPrivateKey: "AUTH_REQUEST_PRIVATE_KEY",
                    method: .userKey(protectedUserKey: "KEY"),
                ),
            ),
        )
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)
    }

    // `unlockVaultWithPassword(_:)` unlocks the vault with the user's password and clears an
    // existing PIN if `enrollPinWithEncryptedPin(encryptedPin:)` fails.
    func test_unlockVaultWithPassword_enrollPinWithEncryptedPinError() async throws {
        // swiftlint:disable:previous function_body_length
        let account = Account.fixture(profile: .fixture(
            userDecryptionOptions: UserDecryptionOptions(
                hasMasterPassword: true,
                masterPasswordUnlock: .fixture(),
                keyConnectorOption: nil,
                trustedDeviceOption: nil,
            ),
        ))
        clientService.mockCrypto.enrollPinWithEncryptedPinResult = .failure(BitwardenTestError.example)
        stateService.activeAccount = account
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        ]
        stateService.encryptedPinByUserId[account.profile.userId] = "encryptedPin"
        stateService.pinProtectedUserKeyEnvelopeValue[account.profile.userId] = "pinProtectedUserKeyEnvelope"

        try await subject.unlockVaultWithPassword(password: "password")

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                accountCryptographicState: .v2(
                    privateKey: "WRAPPED_PRIVATE_KEY",
                    signedPublicKey: "SIGNED_PUBLIC_KEY",
                    signingKey: "WRAPPED_SIGNING_KEY",
                    securityState: "SECURITY_STATE",
                ),
                method: .masterPasswordUnlock(
                    password: "password",
                    masterPasswordUnlock: MasterPasswordUnlockData(
                        kdf: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                        masterKeyWrappedUserKey: "MASTER_KEY_ENCRYPTED_USER_KEY",
                        salt: "SALT",
                    ),
                ),
            ),
        )
        XCTAssertFalse(vaultTimeoutService.isLocked(userId: "1"))
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)

        // Existing PIN is cleared if enrolling the PIN fails.
        XCTAssertEqual(clientService.mockCrypto.enrollPinWithEncryptedPinEncryptedPin, "encryptedPin")
        XCTAssertNil(stateService.accountVolatileData["1"]?.pinProtectedUserKey)
        XCTAssertNil(stateService.encryptedPinByUserId["1"])
        XCTAssertNil(stateService.pinProtectedUserKeyValue["1"])
        XCTAssertEqual(flightRecorder.logMessages, [
            "[Auth] Vault unlocked, method: Master Password Unlock",
            "[Auth] enrollPinWithEncryptedPin failed: example, clearing existing PIN keys",
        ])
    }

    // `unlockVaultWithPassword(_:)` unlocks the vault with the user's password and migrates the
    // legacy pin keys.
    func test_unlockVaultWithPassword_migratesPinProtectedUserKey() async throws {
        // swiftlint:disable:previous function_body_length
        let account = Account.fixture(profile: .fixture(
            userDecryptionOptions: UserDecryptionOptions(
                hasMasterPassword: true,
                masterPasswordUnlock: .fixture(),
                keyConnectorOption: nil,
                trustedDeviceOption: nil,
            ),
        ))
        clientService.mockCrypto.enrollPinWithEncryptedPinResult = .success(
            EnrollPinResponse(
                pinProtectedUserKeyEnvelope: "pinProtectedUserKeyEnvelope",
                userKeyEncryptedPin: "userKeyEncryptedPin",
            ),
        )
        stateService.activeAccount = account
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        ]
        stateService.encryptedPinByUserId[account.profile.userId] = "encryptedPin"
        stateService.pinProtectedUserKeyValue[account.profile.userId] = "pinProtectedUserKey"

        try await subject.unlockVaultWithPassword(password: "password")

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                accountCryptographicState: .v2(
                    privateKey: "WRAPPED_PRIVATE_KEY",
                    signedPublicKey: "SIGNED_PUBLIC_KEY",
                    signingKey: "WRAPPED_SIGNING_KEY",
                    securityState: "SECURITY_STATE",
                ),
                method: .masterPasswordUnlock(
                    password: "password",
                    masterPasswordUnlock: MasterPasswordUnlockData(
                        kdf: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                        masterKeyWrappedUserKey: "MASTER_KEY_ENCRYPTED_USER_KEY",
                        salt: "SALT",
                    ),
                ),
            ),
        )
        XCTAssertFalse(vaultTimeoutService.isLocked(userId: "1"))
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)

        // Existing pin is migrated to pin protected key envelope.
        XCTAssertEqual(clientService.mockCrypto.enrollPinWithEncryptedPinEncryptedPin, "encryptedPin")
        XCTAssertNil(stateService.accountVolatileData["1"]?.pinProtectedUserKey)
        XCTAssertEqual(stateService.encryptedPinByUserId["1"], "userKeyEncryptedPin")
        XCTAssertEqual(stateService.pinProtectedUserKeyEnvelopeValue["1"], "pinProtectedUserKeyEnvelope")
        XCTAssertEqual(flightRecorder.logMessages, [
            "[Auth] Vault unlocked, method: Master Password Unlock",
            "[Auth] Migrated from legacy PIN to PIN-protected user key envelope",
        ])
    }

    // `unlockVaultWithPassword(_:)` unlocks the vault with the user's password and sets the
    // PIN-protected user key in memory.
    func test_unlockVaultWithPassword_setsPinProtectedUserKeyInMemory() async throws {
        // swiftlint:disable:previous function_body_length
        let account = Account.fixture(profile: .fixture(
            userDecryptionOptions: UserDecryptionOptions(
                hasMasterPassword: true,
                masterPasswordUnlock: .fixture(),
                keyConnectorOption: nil,
                trustedDeviceOption: nil,
            ),
        ))
        clientService.mockCrypto.enrollPinWithEncryptedPinResult = .success(
            EnrollPinResponse(
                pinProtectedUserKeyEnvelope: "pinProtectedUserKeyEnvelope",
                userKeyEncryptedPin: "userKeyEncryptedPin",
            ),
        )
        stateService.activeAccount = account
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        ]
        stateService.encryptedPinByUserId[account.profile.userId] = "encryptedPin"
        stateService.pinUnlockRequiresPasswordAfterRestartValue = true

        try await subject.unlockVaultWithPassword(password: "password")

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                accountCryptographicState: .v2(
                    privateKey: "WRAPPED_PRIVATE_KEY",
                    signedPublicKey: "SIGNED_PUBLIC_KEY",
                    signingKey: "WRAPPED_SIGNING_KEY",
                    securityState: "SECURITY_STATE",
                ),
                method: .masterPasswordUnlock(
                    password: "password",
                    masterPasswordUnlock: MasterPasswordUnlockData(
                        kdf: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                        masterKeyWrappedUserKey: "MASTER_KEY_ENCRYPTED_USER_KEY",
                        salt: "SALT",
                    ),
                ),
            ),
        )
        XCTAssertFalse(vaultTimeoutService.isLocked(userId: "1"))
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)

        XCTAssertEqual(clientService.mockCrypto.enrollPinWithEncryptedPinEncryptedPin, "encryptedPin")
        XCTAssertEqual(stateService.accountVolatileData["1"]?.pinProtectedUserKey, "pinProtectedUserKeyEnvelope")
        XCTAssertEqual(stateService.encryptedPinByUserId["1"], "encryptedPin")
        XCTAssertNil(stateService.pinProtectedUserKeyEnvelopeValue["1"])
        XCTAssertEqual(flightRecorder.logMessages, [
            "[Auth] Vault unlocked, method: Master Password Unlock",
            "[Auth] Set PIN-protected user key in memory",
        ])
    }

    /// `unlockVaultWithPIN(_:)` unlocks the vault with the user's PIN and migrates the legacy pin keys.
    func test_unlockVaultWithPIN_pinProtectedUserKey_migratesPinProtectedUserKey() async throws {
        let account = Account.fixture()
        clientService.mockCrypto.enrollPinWithEncryptedPinResult = .success(
            EnrollPinResponse(
                pinProtectedUserKeyEnvelope: "pinProtectedUserKeyEnvelope",
                userKeyEncryptedPin: "userKeyEncryptedPin",
            ),
        )
        stateService.activeAccount = account
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        ]
        stateService.encryptedPinByUserId[account.profile.userId] = "encryptedPin"
        stateService.pinProtectedUserKeyValue[account.profile.userId] = "pinProtectedUserKey"

        try await subject.unlockVaultWithPIN(pin: "123")

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                accountCryptographicState: .v2(
                    privateKey: "WRAPPED_PRIVATE_KEY",
                    signedPublicKey: "SIGNED_PUBLIC_KEY",
                    signingKey: "WRAPPED_SIGNING_KEY",
                    securityState: "SECURITY_STATE",
                ),
                method: .pin(pin: "123", pinProtectedUserKey: "pinProtectedUserKey"),
            ),
        )
        XCTAssertFalse(vaultTimeoutService.isLocked(userId: "1"))
        XCTAssertTrue(vaultTimeoutService.unlockVaultHadUserInteraction)
        XCTAssertEqual(stateService.manuallyLockedAccounts["1"], false)

        // Existing pin is migrated to pin protected key envelope.
        XCTAssertEqual(clientService.mockCrypto.enrollPinWithEncryptedPinEncryptedPin, "encryptedPin")
        XCTAssertEqual(stateService.pinProtectedUserKeyEnvelopeValue["1"], "pinProtectedUserKeyEnvelope")
        XCTAssertEqual(stateService.encryptedPinByUserId["1"], "userKeyEncryptedPin")
        XCTAssertEqual(flightRecorder.logMessages, [
            "[Auth] Vault unlocked, method: PIN",
            "[Auth] Migrated from legacy PIN to PIN-protected user key envelope",
        ])
    }

    /// `unlockVaultWithPIN(_:)` unlocks the vault with the user's PIN using the pin protected user key envelope.
    func test_unlockVaultWithPIN_pinProtectedUserKeyEnvelope() async throws {
        let account = Account.fixture()
        stateService.activeAccount = account
        stateService.accountEncryptionKeys = [
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
        ]
        stateService.pinProtectedUserKeyEnvelopeValue[account.profile.userId] = "pinProtectedUserKeyEnvelope"

        try await subject.unlockVaultWithPIN(pin: "123")

        XCTAssertEqual(
            clientService.mockCrypto.initializeUserCryptoRequest,
            InitUserCryptoRequest(
                userId: "1",
                kdfParams: .pbkdf2(iterations: UInt32(Constants.pbkdf2Iterations)),
                email: "user@bitwarden.com",
                accountCryptographicState: .v2(
                    privateKey: "WRAPPED_PRIVATE_KEY",
                    signedPublicKey: "SIGNED_PUBLIC_KEY",
                    signingKey: "WRAPPED_SIGNING_KEY",
                    securityState: "SECURITY_STATE",
                ),
                method: .pinEnvelope(pin: "123", pinProtectedUserKeyEnvelope: "pinProtectedUserKeyEnvelope"),
            ),
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
        clientService.mockCrypto.makeUpdatePasswordResult = .failure(BitwardenTestError.example)
        stateService.activeAccount = .fixture()

        await assertAsyncThrows(error: BitwardenTestError.example) {
            try await subject.updateMasterPassword(
                currentPassword: "PASSWORD",
                newPassword: "NEW_PASSWORD",
                passwordHint: "PASSWORD_HINT",
                reason: .weakMasterPasswordOnLogin,
            )
        }
    }

    /// `updateMasterPassword()` performs the API request to update the user's password.
    func test_updateMasterPassword_weakMasterPasswordOnLogin() async throws {
        client.result = .httpSuccess(testData: .emptyResponse)
        clientService.mockCrypto.makeUpdatePasswordResult = .success(
            UpdatePasswordResponse(passwordHash: "NEW_PASSWORD_HASH", newKey: "NEW_KEY"),
        )
        stateService.accountEncryptionKeys["1"] = AccountEncryptionKeys(
            accountKeys: .fixtureFilled(),
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "KEY",
        )
        stateService.activeAccount = .fixture()
        stateService.masterPasswordHashes["1"] = "MASTER_PASSWORD_HASH"
        stateService.forcePasswordResetReason["1"] = .adminForcePasswordReset

        try await subject.updateMasterPassword(
            currentPassword: "PASSWORD",
            newPassword: "NEW_PASSWORD",
            passwordHint: "PASSWORD_HINT",
            reason: .weakMasterPasswordOnLogin,
        )

        XCTAssertEqual(clientService.mockCrypto.makeUpdatePasswordNewPassword, "NEW_PASSWORD")

        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotNil(client.requests[0].body)
        XCTAssertEqual(client.requests[0].method, .post)
        XCTAssertEqual(client.requests[0].url.absoluteString, "https://example.com/api/accounts/password")

        XCTAssertEqual(stateService.masterPasswordHashes["1"], "NEW_PASSWORD_HASH")
        XCTAssertEqual(
            stateService.accountEncryptionKeys["1"],
            AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "NEW_KEY",
            ),
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
            accountKeys: .fixtureFilled(),
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "KEY",
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
            accountKeys: .fixtureFilled(),
            encryptedPrivateKey: "PRIVATE_KEY",
            encryptedUserKey: "KEY",
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
            "1": AccountEncryptionKeys(
                accountKeys: .fixtureFilled(),
                encryptedPrivateKey: "PRIVATE_KEY",
                encryptedUserKey: "USER_KEY",
            ),
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
