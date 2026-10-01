import BitwardenKitMocks
import BitwardenSdk
import TestHelpers
import Testing

@testable import BitwardenShared
@testable import BitwardenSharedMocks

// MARK: - SdkStateBridgeTests

struct SdkStateBridgeTests {
    // MARK: Properties

    let errorReporter: MockErrorReporter
    let stateService: MockSdkStateBridgeStateService
    let subject: SdkStateBridge

    // MARK: Initialization

    init() {
        errorReporter = MockErrorReporter()
        stateService = MockSdkStateBridgeStateService()
        subject = SdkStateBridge(
            errorReporter: errorReporter,
            stateService: stateService,
            userId: "1",
        )
    }

    // MARK: Tests - Account Cryptographic State

    /// `clearAccountCryptographicState()` clears the value via `StateService` for the bridge's user.
    @Test
    func clearAccountCryptographicState() async {
        await subject.clearAccountCryptographicState()

        #expect(stateService.setAccountCryptographicStateReceivedArguments?.state == nil)
        #expect(stateService.setAccountCryptographicStateReceivedArguments?.userId == "1")
    }

    /// `getAccountCryptographicState()` returns the value from `StateService` for the bridge's user.
    @Test
    func getAccountCryptographicState() async {
        let state = WrappedAccountCryptographicState.v1(privateKey: "PRIVATE_KEY")
        stateService.getAccountCryptographicStateReturnValue = state

        let result = await subject.getAccountCryptographicState()

        #expect(result == state)
        #expect(stateService.getAccountCryptographicStateReceivedUserId == "1")
    }

    /// `setAccountCryptographicState(value:)` sets the value via `StateService` for the bridge's user.
    @Test
    func setAccountCryptographicState() async {
        let state = WrappedAccountCryptographicState.v1(privateKey: "PRIVATE_KEY")

        await subject.setAccountCryptographicState(value: state)

        #expect(stateService.setAccountCryptographicStateReceivedArguments?.state == state)
        #expect(stateService.setAccountCryptographicStateReceivedArguments?.userId == "1")
    }

    // MARK: Tests - Encrypted Pin

    /// `clearEncryptedPin()` clears the value via `StateService` for the bridge's user.
    @Test
    func clearEncryptedPin() async {
        await subject.clearEncryptedPin()

        #expect(stateService.setEncryptedPinReceivedArguments?.encryptedPin == nil)
        #expect(stateService.setEncryptedPinReceivedArguments?.userId == "1")
    }

    /// `getEncryptedPin()` returns the value from `StateService` for the bridge's user.
    @Test
    func getEncryptedPin() async {
        let pin: EncString = "ENCRYPTED_PIN"
        stateService.getEncryptedPinReturnValue = pin

        let result = await subject.getEncryptedPin()

        #expect(result == pin)
        #expect(stateService.getEncryptedPinReceivedUserId == "1")
    }

    /// `getEncryptedPin()` returns `nil` and logs an error if `StateService` throws.
    @Test
    func getEncryptedPin_error() async {
        stateService.getEncryptedPinThrowableError = BitwardenTestError.example

        let result = await subject.getEncryptedPin()

        #expect(result == nil)
        #expect(errorReporter.errors.last as? BitwardenTestError == .example)
    }

    /// `setEncryptedPin(value:)` sets the value via `StateService` for the bridge's user.
    @Test
    func setEncryptedPin() async {
        let pin: EncString = "ENCRYPTED_PIN"

        await subject.setEncryptedPin(value: pin)

        #expect(stateService.setEncryptedPinReceivedArguments?.encryptedPin == pin)
        #expect(stateService.setEncryptedPinReceivedArguments?.userId == "1")
    }

    // MARK: Tests - Ephemeral Pin Envelope

    /// `clearEphemeralPinEnvelope()` clears the value via `StateService` for the bridge's user.
    @Test
    func clearEphemeralPinEnvelope() async {
        await subject.clearEphemeralPinEnvelope()

        #expect(stateService.setEphemeralPinEnvelopeReceivedArguments?.envelope == nil)
        #expect(stateService.setEphemeralPinEnvelopeReceivedArguments?.userId == "1")
    }

    /// `getEphemeralPinEnvelope()` returns the value from `StateService` for the bridge's user.
    @Test
    func getEphemeralPinEnvelope() async {
        let envelope: PasswordProtectedKeyEnvelope = "EPHEMERAL_PIN_ENVELOPE"
        stateService.getEphemeralPinEnvelopeReturnValue = envelope

        let result = await subject.getEphemeralPinEnvelope()

        #expect(result == envelope)
        #expect(stateService.getEphemeralPinEnvelopeReceivedUserId == "1")
    }

    /// `setEphemeralPinEnvelope(value:)` sets the value via `StateService` for the bridge's user.
    @Test
    func setEphemeralPinEnvelope() async {
        let envelope: PasswordProtectedKeyEnvelope = "EPHEMERAL_PIN_ENVELOPE"

        await subject.setEphemeralPinEnvelope(value: envelope)

        #expect(stateService.setEphemeralPinEnvelopeReceivedArguments?.envelope == envelope)
        #expect(stateService.setEphemeralPinEnvelopeReceivedArguments?.userId == "1")
    }

    // MARK: Tests - Kdf Config

    /// `clearKdfConfig()` clears the value via `StateService` for the bridge's user.
    @Test
    func clearKdfConfig() async {
        await subject.clearKdfConfig()

        #expect(stateService.clearKdfConfigReceivedUserId == "1")
    }

    /// `getKdfConfig()` returns the value from `StateService` for the bridge's user.
    @Test
    func getKdfConfig() async {
        let kdf = BitwardenSdk.Kdf.pbkdf2(iterations: 600_000)
        stateService.getKdfConfigReturnValue = kdf

        let result = await subject.getKdfConfig()

        #expect(result == kdf)
        #expect(stateService.getKdfConfigReceivedUserId == "1")
    }

    /// `setKdfConfig(value:)` sets the value via `StateService` for the bridge's user.
    @Test
    func setKdfConfig() async {
        let kdf = BitwardenSdk.Kdf.pbkdf2(iterations: 600_000)

        await subject.setKdfConfig(value: kdf)

        #expect(stateService.setKdfConfigReceivedArguments?.kdf == kdf)
        #expect(stateService.setKdfConfigReceivedArguments?.userId == "1")
    }

    // MARK: Tests - Master Password Unlock Data

    /// `clearMasterpasswordUnlockData()` clears the account's master password unlock data via
    /// `StateService`.
    @Test
    func clearMasterpasswordUnlockData() async {
        await subject.clearMasterpasswordUnlockData()

        #expect(stateService.clearAccountMasterPasswordUnlockDataReceivedUserId == "1")
    }

    /// `getMasterpasswordUnlockData()` returns the value from `StateService` for the bridge's user.
    @Test
    func getMasterpasswordUnlockData() async {
        let unlockData = MasterPasswordUnlockData(
            kdf: .pbkdf2(iterations: 600_000),
            masterKeyWrappedUserKey: "MASTER_KEY_WRAPPED_USER_KEY",
            salt: "SALT",
        )
        stateService.getAccountMasterPasswordUnlockReturnValue = unlockData

        let result = await subject.getMasterpasswordUnlockData()

        #expect(result == unlockData)
        #expect(stateService.getAccountMasterPasswordUnlockReceivedUserId == "1")
    }

    /// `setMasterpasswordUnlockData(value:)` sets the account's master password unlock data via
    /// `StateService`, converting from the SDK's type.
    @Test
    func setMasterpasswordUnlockData() async {
        let unlockData = MasterPasswordUnlockData(
            kdf: .pbkdf2(iterations: 600_000),
            masterKeyWrappedUserKey: "MASTER_KEY_WRAPPED_USER_KEY",
            salt: "SALT",
        )

        await subject.setMasterpasswordUnlockData(value: unlockData)

        #expect(
            stateService.setAccountMasterPasswordUnlockReceivedArguments?.masterPasswordUnlock ==
                MasterPasswordUnlockResponseModel(unlockData: unlockData),
        )
        #expect(stateService.setAccountMasterPasswordUnlockReceivedArguments?.userId == "1")
    }

    // MARK: Tests - Persistent Pin Envelope

    /// `clearPersistentPinEnvelope()` clears the value via `StateService` for the bridge's user.
    @Test
    func clearPersistentPinEnvelope() async {
        await subject.clearPersistentPinEnvelope()

        #expect(stateService.setPersistentPinEnvelopeReceivedArguments?.envelope == nil)
        #expect(stateService.setPersistentPinEnvelopeReceivedArguments?.userId == "1")
    }

    /// `getPersistentPinEnvelope()` returns the value from `StateService` for the bridge's user.
    @Test
    func getPersistentPinEnvelope() async {
        let envelope: PasswordProtectedKeyEnvelope = "PIN_ENVELOPE"
        stateService.getPersistentPinEnvelopeReturnValue = envelope

        let result = await subject.getPersistentPinEnvelope()

        #expect(result == envelope)
        #expect(stateService.getPersistentPinEnvelopeReceivedUserId == "1")
    }

    /// `setPersistentPinEnvelope(value:)` sets the value via `StateService` for the bridge's user.
    @Test
    func setPersistentPinEnvelope() async {
        let envelope: PasswordProtectedKeyEnvelope = "PIN_ENVELOPE"

        await subject.setPersistentPinEnvelope(value: envelope)

        #expect(stateService.setPersistentPinEnvelopeReceivedArguments?.envelope == envelope)
        #expect(stateService.setPersistentPinEnvelopeReceivedArguments?.userId == "1")
    }

    // MARK: Tests - User Key

    /// `getUserKey()`/`setUserKey(value:)`/`clearUserKey()` hold the user key in memory only.
    @Test
    func userKey() async {
        let key: SymmetricCryptoKey = "USER_KEY"

        let initial = await subject.getUserKey()
        #expect(initial == nil)

        await subject.setUserKey(value: key)
        let stored = await subject.getUserKey()
        #expect(stored == key)

        await subject.clearUserKey()
        let cleared = await subject.getUserKey()
        #expect(cleared == nil)
    }

    // MARK: Tests - User Key Id

    /// `clearUserKeyId()` clears the value via `StateService` for the bridge's user.
    @Test
    func clearUserKeyId() async {
        await subject.clearUserKeyId()

        #expect(stateService.setUserKeyIdReceivedArguments?.keyId == nil)
        #expect(stateService.setUserKeyIdReceivedArguments?.userId == "1")
    }

    /// `getUserKeyId()` returns the value from `StateService` for the bridge's user.
    @Test
    func getUserKeyId() async {
        stateService.getUserKeyIdReturnValue = "USER_KEY_ID"

        let result = await subject.getUserKeyId()

        #expect(result == "USER_KEY_ID")
        #expect(stateService.getUserKeyIdReceivedUserId == "1")
    }

    /// `setUserKeyId(value:)` sets the value via `StateService` for the bridge's user.
    @Test
    func setUserKeyId() async {
        await subject.setUserKeyId(value: "USER_KEY_ID")

        #expect(stateService.setUserKeyIdReceivedArguments?.keyId == "USER_KEY_ID")
        #expect(stateService.setUserKeyIdReceivedArguments?.userId == "1")
    }

    // MARK: Tests - V2 Upgrade Token

    /// `clearV2UpgradeToken()` clears the value via `StateService` for the bridge's user.
    @Test
    func clearV2UpgradeToken() async {
        await subject.clearV2UpgradeToken()

        #expect(stateService.setV2UpgradeTokenReceivedArguments?.token == nil)
        #expect(stateService.setV2UpgradeTokenReceivedArguments?.userId == "1")
    }

    /// `getV2UpgradeToken()` returns the value from `StateService` for the bridge's user.
    @Test
    func getV2UpgradeToken() async {
        let token = V2UpgradeToken(wrappedUserKey1: "WRAPPED_USER_KEY_1", wrappedUserKey2: "WRAPPED_USER_KEY_2")
        stateService.getV2UpgradeTokenReturnValue = token

        let result = await subject.getV2UpgradeToken()

        #expect(result == token)
        #expect(stateService.getV2UpgradeTokenReceivedUserId == "1")
    }

    /// `setV2UpgradeToken(value:)` sets the value via `StateService` for the bridge's user.
    @Test
    func setV2UpgradeToken() async {
        let token = V2UpgradeToken(wrappedUserKey1: "WRAPPED_USER_KEY_1", wrappedUserKey2: "WRAPPED_USER_KEY_2")

        await subject.setV2UpgradeToken(value: token)

        #expect(stateService.setV2UpgradeTokenReceivedArguments?.token == token)
        #expect(stateService.setV2UpgradeTokenReceivedArguments?.userId == "1")
    }

    // MARK: Tests - WebAuthn Prf Unlock Data

    /// `clearWebauthnPrfUnlockData()` is a no-op since the app doesn't support WebAuthn PRF unlock.
    @Test
    func clearWebauthnPrfUnlockData() async {
        await subject.clearWebauthnPrfUnlockData()

        let result = await subject.getWebauthnPrfUnlockData()
        #expect(result == nil)
    }

    /// `getWebauthnPrfUnlockData()` always returns `nil` since the app doesn't support WebAuthn PRF
    /// unlock.
    @Test
    func getWebauthnPrfUnlockData() async {
        let result = await subject.getWebauthnPrfUnlockData()

        #expect(result == nil)
    }

    /// `setWebauthnPrfUnlockData(value:)` is a no-op since the app doesn't support WebAuthn PRF unlock.
    @Test
    func setWebauthnPrfUnlockData() async {
        let data = WebAuthnPrfUnlockData(options: [])

        await subject.setWebauthnPrfUnlockData(value: data)

        let result = await subject.getWebauthnPrfUnlockData()
        #expect(result == nil)
    }
}
