import BitwardenKit
import BitwardenSdk

// MARK: - SdkStateBridge

/// A user-scoped implementation of the Bitwarden SDK's key management state bridge
/// (`StateBridgeForeignImpl`), allowing the SDK to read, write, and clear mobile state directly
/// instead of requiring the app to pass it explicitly on every call.
///
actor SdkStateBridge: StateBridgeForeignImpl {
    // MARK: Private Properties

    /// The service used by the application to report non-fatal errors.
    private let errorReporter: ErrorReporter

    /// The service used to manage the account state this bridge reads from and writes to.
    private let stateService: SdkStateBridgeStateService

    /// The ID of the user this bridge is scoped to.
    private let userId: String

    /// The user's symmetric encryption key, held in memory only. This must never be persisted.
    private var userKey: SymmetricCryptoKey?

    // MARK: Initialization

    /// Initializes a new `SdkStateBridge`.
    ///
    /// - Parameters:
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used to manage the account state this bridge reads from and
    ///     writes to.
    ///   - userId: The ID of the user this bridge is scoped to.
    ///
    init(
        errorReporter: ErrorReporter,
        stateService: SdkStateBridgeStateService,
        userId: String,
    ) {
        self.errorReporter = errorReporter
        self.stateService = stateService
        self.userId = userId
    }

    // MARK: Account Cryptographic State

    func clearAccountCryptographicState() async {
        await stateService.setAccountCryptographicState(nil, userId: userId)
    }

    func getAccountCryptographicState() async -> WrappedAccountCryptographicState? {
        await stateService.getAccountCryptographicState(userId: userId)
    }

    func setAccountCryptographicState(value: WrappedAccountCryptographicState) async {
        await stateService.setAccountCryptographicState(value, userId: userId)
    }

    // MARK: Encrypted Pin

    func clearEncryptedPin() async {
        await stateService.setEncryptedPin(nil, userId: userId)
    }

    func getEncryptedPin() async -> EncString? {
        do {
            return try await stateService.getEncryptedPin(userId: userId)
        } catch {
            errorReporter.log(error: error)
            return nil
        }
    }

    func setEncryptedPin(value: EncString) async {
        await stateService.setEncryptedPin(value, userId: userId)
    }

    // MARK: Ephemeral Pin Envelope

    func clearEphemeralPinEnvelope() async {
        await stateService.setEphemeralPinEnvelope(nil, userId: userId)
    }

    func getEphemeralPinEnvelope() async -> PasswordProtectedKeyEnvelope? {
        await stateService.getEphemeralPinEnvelope(userId: userId)
    }

    func setEphemeralPinEnvelope(value: PasswordProtectedKeyEnvelope) async {
        await stateService.setEphemeralPinEnvelope(value, userId: userId)
    }

    // MARK: Master Password Unlock Data

    func clearMasterpasswordUnlockData() async {
        await stateService.clearAccountMasterPasswordUnlockData(userId: userId)
    }

    func getMasterpasswordUnlockData() async -> MasterPasswordUnlockData? {
        await stateService.getAccountMasterPasswordUnlock(userId: userId)
    }

    func setMasterpasswordUnlockData(value: MasterPasswordUnlockData) async {
        await stateService.setAccountMasterPasswordUnlock(
            MasterPasswordUnlockResponseModel(unlockData: value),
            userId: userId,
        )
    }

    // MARK: Persistent Pin Envelope

    func clearPersistentPinEnvelope() async {
        await stateService.setPersistentPinEnvelope(nil, userId: userId)
    }

    func getPersistentPinEnvelope() async -> PasswordProtectedKeyEnvelope? {
        await stateService.getPersistentPinEnvelope(userId: userId)
    }

    func setPersistentPinEnvelope(value: PasswordProtectedKeyEnvelope) async {
        await stateService.setPersistentPinEnvelope(value, userId: userId)
    }

    // MARK: User Key

    func clearUserKey() {
        userKey = nil
    }

    func getUserKey() -> SymmetricCryptoKey? {
        userKey
    }

    func setUserKey(value: SymmetricCryptoKey) {
        userKey = value
    }

    // MARK: V2 Upgrade Token

    func clearV2UpgradeToken() async {
        await stateService.setV2UpgradeToken(nil, userId: userId)
    }

    func getV2UpgradeToken() async -> V2UpgradeToken? {
        await stateService.getV2UpgradeToken(userId: userId)
    }

    func setV2UpgradeToken(value: V2UpgradeToken) async {
        await stateService.setV2UpgradeToken(value, userId: userId)
    }
}
