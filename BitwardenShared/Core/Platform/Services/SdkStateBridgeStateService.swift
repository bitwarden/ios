import BitwardenSdk

// MARK: - SdkStateBridgeStateService

/// A service that provides state management functionality required by `SdkStateBridge`, the SDK's
/// key management state bridge.
///
protocol SdkStateBridgeStateService { // sourcery: AutoMockable
    // MARK: Account Cryptographic State

    /// Gets the account cryptographic state for an account.
    ///
    /// - Parameter userId: The user ID of the account.
    /// - Returns: The account cryptographic state.
    ///
    func getAccountCryptographicState(userId: String) async -> WrappedAccountCryptographicState?

    /// Sets the account cryptographic state for an account.
    ///
    /// - Parameters:
    ///   - state: The account cryptographic state, or `nil` to clear it.
    ///   - userId: The user ID of the account.
    ///
    func setAccountCryptographicState(_ state: WrappedAccountCryptographicState?, userId: String) async

    // MARK: Encrypted Pin

    /// The user's pin protected by their user key.
    ///
    /// - Parameter userId: The user ID associated with the encrypted pin.
    /// - Returns: The user's pin protected by their user key.
    ///
    func getEncryptedPin(userId: String?) async throws -> String?

    /// Sets the user's pin protected by their user key.
    ///
    /// - Parameters:
    ///   - encryptedPin: The user's pin protected by their user key, or `nil` to clear it.
    ///   - userId: The user ID associated with the encrypted pin.
    ///
    func setEncryptedPin(_ encryptedPin: String?, userId: String) async

    // MARK: Ephemeral Pin Envelope

    /// Gets the user's ephemeral (in-memory) pin protected user key envelope.
    ///
    /// - Parameter userId: The user ID associated with the pin protected user key envelope.
    /// - Returns: The user's ephemeral pin protected user key envelope.
    ///
    func getEphemeralPinEnvelope(userId: String) async -> String?

    /// Sets the user's ephemeral (in-memory) pin protected user key envelope.
    ///
    /// - Parameters:
    ///   - envelope: The user's ephemeral pin protected user key envelope, or `nil` to clear it.
    ///   - userId: The user ID associated with the pin protected user key envelope.
    ///
    func setEphemeralPinEnvelope(_ envelope: String?, userId: String) async

    // MARK: Kdf Config

    /// Clears the account's stored KDF configuration.
    ///
    /// - Parameter userId: The user ID of the account.
    ///
    func clearKdfConfig(userId: String) async

    /// Gets the account's stored KDF configuration.
    ///
    /// - Parameter userId: The user ID of the account.
    /// - Returns: The account's KDF configuration, or `nil` if unavailable.
    ///
    func getKdfConfig(userId: String) async -> BitwardenSdk.Kdf?

    /// Sets the account's KDF configuration.
    ///
    /// - Parameters:
    ///   - kdf: The account's KDF configuration.
    ///   - userId: The user ID of the account.
    ///
    func setKdfConfig(_ kdf: BitwardenSdk.Kdf, userId: String) async

    // MARK: Master Password Unlock Data

    /// Clears the master password unlock data for an account.
    ///
    /// - Parameter userId: The user ID of the account to clear the master password unlock data for.
    ///
    func clearAccountMasterPasswordUnlockData(userId: String) async

    /// Gets the master password unlock data for an account.
    ///
    /// - Parameter userId: The user ID of the account.
    /// - Returns: The account master password unlock data, or `nil` if unavailable.
    ///
    func getAccountMasterPasswordUnlock(userId: String) async -> MasterPasswordUnlockData?

    /// Sets the master password unlock data for an account.
    ///
    /// - Parameters:
    ///   - masterPasswordUnlock: The account master password unlock data.
    ///   - userId: The user ID of the account to associate with the master password unlock data.
    ///
    func setAccountMasterPasswordUnlock(
        _ masterPasswordUnlock: MasterPasswordUnlockResponseModel,
        userId: String,
    ) async

    // MARK: Persistent Pin Envelope

    /// Gets the user's persistent (disk-backed) pin protected user key envelope.
    ///
    /// - Parameter userId: The user ID associated with the pin protected user key envelope.
    /// - Returns: The user's persistent pin protected user key envelope.
    ///
    func getPersistentPinEnvelope(userId: String) async -> String?

    /// Sets the user's persistent (disk-backed) pin protected user key envelope.
    ///
    /// - Parameters:
    ///   - envelope: The user's persistent pin protected user key envelope, or `nil` to clear it.
    ///   - userId: The user ID associated with the pin protected user key envelope.
    ///
    func setPersistentPinEnvelope(_ envelope: String?, userId: String) async

    // MARK: User Key Id

    /// Gets the ID of the account's active user key.
    ///
    /// - Parameter userId: The user ID of the account.
    /// - Returns: The ID of the account's active user key, or `nil` if unavailable.
    ///
    func getUserKeyId(userId: String) async -> String?

    /// Sets the ID of the account's active user key.
    ///
    /// - Parameters:
    ///   - keyId: The ID of the account's active user key, or `nil` to clear it.
    ///   - userId: The user ID of the account.
    ///
    func setUserKeyId(_ keyId: String?, userId: String) async

    // MARK: V2 Upgrade Token

    /// Gets the user's V2 encryption upgrade token.
    ///
    /// - Parameter userId: The user ID of the account.
    /// - Returns: The user's V2 encryption upgrade token.
    ///
    func getV2UpgradeToken(userId: String) async -> V2UpgradeToken?

    /// Sets the user's V2 encryption upgrade token.
    ///
    /// - Parameters:
    ///   - token: The user's V2 encryption upgrade token, or `nil` to clear it.
    ///   - userId: The user ID of the account.
    ///
    func setV2UpgradeToken(_ token: V2UpgradeToken?, userId: String) async
}
