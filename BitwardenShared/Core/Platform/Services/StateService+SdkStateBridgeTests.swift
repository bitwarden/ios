// swiftlint:disable:this file_name

import BitwardenKit
import BitwardenKitMocks
import BitwardenSdk
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - StateServiceSdkStateBridgeTests

struct StateServiceSdkStateBridgeTests {
    // MARK: Properties

    let appSettingsStore: MockAppSettingsStore
    let errorReporter: MockErrorReporter
    let subject: DefaultStateService

    // MARK: Initialization

    init() {
        appSettingsStore = MockAppSettingsStore()
        errorReporter = MockErrorReporter()
        subject = DefaultStateService(
            appSettingsStore: appSettingsStore,
            dataStore: DataStore(errorReporter: MockErrorReporter(), storeType: .memory),
            errorReporter: errorReporter,
            keychainRepository: MockKeychainRepository(),
            timeProvider: MockTimeProvider(.currentTime),
            userSessionKeychainRepository: MockUserSessionKeychainRepository(),
        )
    }

    // MARK: Tests - Account Cryptographic State

    /// `getAccountCryptographicState(userId:)` returns the account cryptographic state stored in
    /// `AppSettingsStore` for the specified user.
    @Test
    func getAccountCryptographicState() async {
        appSettingsStore.accountCryptographicStates["1"] = .fixtureV2()

        let result = await subject.getAccountCryptographicState(userId: "1")

        #expect(result == .fixtureV2())
    }

    /// `getAccountCryptographicState(userId:)` returns `nil` when no state is stored for the user.
    @Test
    func getAccountCryptographicState_nil() async {
        let result = await subject.getAccountCryptographicState(userId: "1")

        #expect(result == nil)
    }

    /// `setAccountCryptographicState(_:userId:)` persists the account cryptographic state to
    /// `AppSettingsStore` for the specified user.
    @Test
    func setAccountCryptographicState() async {
        await subject.setAccountCryptographicState(.fixtureV2(), userId: "1")

        #expect(appSettingsStore.accountCryptographicStates["1"] == .fixtureV2())
    }

    /// `setAccountCryptographicState(_:userId:)` clears the account cryptographic state in
    /// `AppSettingsStore` when passed `nil`.
    @Test
    func setAccountCryptographicState_nil() async {
        appSettingsStore.accountCryptographicStates["1"] = .fixtureV2()

        await subject.setAccountCryptographicState(nil, userId: "1")

        #expect(appSettingsStore.accountCryptographicStates["1"] == nil)
    }

    // MARK: Tests - Encrypted Pin

    /// `setEncryptedPin(_:userId:)` persists the encrypted pin to `AppSettingsStore` for the
    /// specified user.
    @Test
    func setEncryptedPin() async {
        await subject.setEncryptedPin("ENCRYPTED_PIN", userId: "1")

        #expect(appSettingsStore.encryptedPinByUserId["1"] == "ENCRYPTED_PIN")
    }

    /// `setEncryptedPin(_:userId:)` clears the encrypted pin in `AppSettingsStore` when passed `nil`.
    @Test
    func setEncryptedPin_nil() async {
        appSettingsStore.encryptedPinByUserId["1"] = "ENCRYPTED_PIN"

        await subject.setEncryptedPin(nil, userId: "1")

        #expect(appSettingsStore.encryptedPinByUserId["1"] == nil)
    }

    // MARK: Tests - Ephemeral Pin Envelope

    /// `getEphemeralPinEnvelope(userId:)` returns the in-memory pin protected user key envelope
    /// for the specified user.
    @Test
    func getEphemeralPinEnvelope() async {
        await subject.setEphemeralPinEnvelope("PIN_PROTECTED_USER_KEY_ENVELOPE", userId: "1")

        let result = await subject.getEphemeralPinEnvelope(userId: "1")

        #expect(result == "PIN_PROTECTED_USER_KEY_ENVELOPE")
    }

    /// `getEphemeralPinEnvelope(userId:)` returns `nil` when no envelope is stored in memory for
    /// the user.
    @Test
    func getEphemeralPinEnvelope_nil() async {
        let result = await subject.getEphemeralPinEnvelope(userId: "1")

        #expect(result == nil)
    }

    /// `setEphemeralPinEnvelope(_:userId:)` stores the pin protected user key envelope in memory
    /// for the specified user.
    @Test
    func setEphemeralPinEnvelope() async {
        await subject.setEphemeralPinEnvelope("PIN_PROTECTED_USER_KEY_ENVELOPE", userId: "1")

        let volatileData = await subject.accountVolatileData["1"]
        #expect(volatileData?.pinProtectedUserKey == "PIN_PROTECTED_USER_KEY_ENVELOPE")
    }

    /// `setEphemeralPinEnvelope(_:userId:)` clears the in-memory pin protected user key envelope
    /// when passed `nil`.
    @Test
    func setEphemeralPinEnvelope_nil() async {
        await subject.setEphemeralPinEnvelope("PIN_PROTECTED_USER_KEY_ENVELOPE", userId: "1")

        await subject.setEphemeralPinEnvelope(nil, userId: "1")

        let result = await subject.getEphemeralPinEnvelope(userId: "1")
        #expect(result == nil)
    }

    // MARK: Tests - Master Password Unlock Data

    /// `clearAccountMasterPasswordUnlockData(userId:)` clears the master password unlock data for
    /// the specified user, without requiring that user to be the active account.
    @Test
    func clearAccountMasterPasswordUnlockData() async throws {
        await subject.addAccount(.fixture(
            profile: .fixture(
                userDecryptionOptions: UserDecryptionOptions(
                    hasMasterPassword: true,
                    masterPasswordUnlock: .fixture(),
                    keyConnectorOption: nil,
                    trustedDeviceOption: nil,
                ),
                userId: "1",
            ),
        ))
        await subject.addAccount(.fixture(profile: .fixture(userId: "2")))
        await subject.setAccountMasterPasswordUnlock(.fixture(), userId: "2")

        await subject.clearAccountMasterPasswordUnlockData(userId: "1")

        #expect(appSettingsStore.state?.accounts["1"]?.profile.userDecryptionOptions?.masterPasswordUnlock == nil)
        #expect(appSettingsStore.state?.accounts["2"]?.profile.userDecryptionOptions?.masterPasswordUnlock != nil)
    }

    /// `clearAccountMasterPasswordUnlockData(userId:)` logs an error if the account can't be found.
    @Test
    func clearAccountMasterPasswordUnlockData_noAccount() async throws {
        await subject.clearAccountMasterPasswordUnlockData(userId: "1")

        #expect(!errorReporter.errors.isEmpty)
    }

    /// `getAccountMasterPasswordUnlock(userId:)` returns the specified user's master password
    /// unlock data, converted to the SDK's type.
    @Test
    func getAccountMasterPasswordUnlock() async throws {
        let responseModel = MasterPasswordUnlockResponseModel.fixture()
        await subject.addAccount(.fixture(
            profile: .fixture(
                userDecryptionOptions: UserDecryptionOptions(
                    hasMasterPassword: true,
                    masterPasswordUnlock: responseModel,
                    keyConnectorOption: nil,
                    trustedDeviceOption: nil,
                ),
                userId: "1",
            ),
        ))

        let result = await subject.getAccountMasterPasswordUnlock(userId: "1")

        #expect(result == MasterPasswordUnlockData(responseModel: responseModel))
    }

    /// `getAccountMasterPasswordUnlock(userId:)` returns `nil` and logs an error if the account
    /// can't be found.
    @Test
    func getAccountMasterPasswordUnlock_noAccount() async throws {
        let result = await subject.getAccountMasterPasswordUnlock(userId: "1")

        #expect(result == nil)
        #expect(!errorReporter.errors.isEmpty)
    }

    // MARK: Tests - Persistent Pin Envelope

    /// `getPersistentPinEnvelope(userId:)` returns the disk-backed pin protected user key envelope
    /// stored in `AppSettingsStore` for the specified user.
    @Test
    func getPersistentPinEnvelope() async {
        appSettingsStore.pinProtectedUserKeyEnvelope["1"] = "PIN_PROTECTED_USER_KEY_ENVELOPE"

        let result = await subject.getPersistentPinEnvelope(userId: "1")

        #expect(result == "PIN_PROTECTED_USER_KEY_ENVELOPE")
    }

    /// `getPersistentPinEnvelope(userId:)` returns `nil` when no envelope is stored for the user.
    @Test
    func getPersistentPinEnvelope_nil() async {
        let result = await subject.getPersistentPinEnvelope(userId: "1")

        #expect(result == nil)
    }

    /// `setPersistentPinEnvelope(_:userId:)` persists the pin protected user key envelope to
    /// `AppSettingsStore` for the specified user.
    @Test
    func setPersistentPinEnvelope() async {
        await subject.setPersistentPinEnvelope("PIN_PROTECTED_USER_KEY_ENVELOPE", userId: "1")

        #expect(appSettingsStore.pinProtectedUserKeyEnvelope["1"] == "PIN_PROTECTED_USER_KEY_ENVELOPE")
    }

    /// `setPersistentPinEnvelope(_:userId:)` clears the envelope in `AppSettingsStore` when passed
    /// `nil`.
    @Test
    func setPersistentPinEnvelope_nil() async {
        appSettingsStore.pinProtectedUserKeyEnvelope["1"] = "PIN_PROTECTED_USER_KEY_ENVELOPE"

        await subject.setPersistentPinEnvelope(nil, userId: "1")

        #expect(appSettingsStore.pinProtectedUserKeyEnvelope["1"] == nil)
    }

    // MARK: Tests - V2 Upgrade Token

    /// `getV2UpgradeToken(userId:)` returns the V2 upgrade token stored in `AppSettingsStore` for
    /// the specified user.
    @Test
    func getV2UpgradeToken() async {
        let token = V2UpgradeToken(wrappedUserKey1: "WRAPPED_USER_KEY_1", wrappedUserKey2: "WRAPPED_USER_KEY_2")
        appSettingsStore.v2UpgradeTokenByUserId["1"] = token

        let result = await subject.getV2UpgradeToken(userId: "1")

        #expect(result == token)
    }

    /// `getV2UpgradeToken(userId:)` returns `nil` when no token is stored for the user.
    @Test
    func getV2UpgradeToken_nil() async {
        let result = await subject.getV2UpgradeToken(userId: "1")

        #expect(result == nil)
    }

    /// `setV2UpgradeToken(_:userId:)` persists the V2 upgrade token to `AppSettingsStore` for the
    /// specified user.
    @Test
    func setV2UpgradeToken() async {
        let token = V2UpgradeToken(wrappedUserKey1: "WRAPPED_USER_KEY_1", wrappedUserKey2: "WRAPPED_USER_KEY_2")

        await subject.setV2UpgradeToken(token, userId: "1")

        #expect(appSettingsStore.v2UpgradeTokenByUserId["1"] == token)
    }

    /// `setV2UpgradeToken(_:userId:)` clears the token in `AppSettingsStore` when passed `nil`.
    @Test
    func setV2UpgradeToken_nil() async {
        let token = V2UpgradeToken(wrappedUserKey1: "WRAPPED_USER_KEY_1", wrappedUserKey2: "WRAPPED_USER_KEY_2")
        appSettingsStore.v2UpgradeTokenByUserId["1"] = token

        await subject.setV2UpgradeToken(nil, userId: "1")

        #expect(appSettingsStore.v2UpgradeTokenByUserId["1"] == nil)
    }
}
