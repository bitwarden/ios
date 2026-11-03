import BitwardenSdk

/// Extension for helper functions of `CryptoClientProtocol`.
extension CryptoClientProtocol {
    // MARK: Methods

    /// Initialization method for the user crypto. Needs to be called before any other crypto operations.
    /// - Parameters:
    ///   - account: The account of the user to initialize crypto.
    ///   - cryptographicState: The account's cryptographic state.
    ///   - method: The crypto initialization method.
    ///   - upgradeToken: The V2 upgrade token, if one is available, to migrate the user's key from V1 to V2.
    func initializeUserCrypto(
        account: Account,
        cryptographicState: WrappedAccountCryptographicState,
        method: InitUserCryptoMethod,
        upgradeToken: V2UpgradeToken?,
    ) async throws {
        try await initializeUserCrypto(
            req: InitUserCryptoRequest(
                userId: account.profile.userId,
                kdfParams: account.kdf.sdkKdf,
                email: account.profile.email,
                accountCryptographicState: cryptographicState,
                method: method,
                upgradeToken: upgradeToken,
            ),
        )
    }
}
