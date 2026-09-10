import BitwardenSdk

/// Extension for helper functions of `CryptoClientProtocol`.
extension CryptoClientProtocol {
    // MARK: Methods

    /// Initialization method for the user crypto. Needs to be called before any other crypto operations.
    /// - Parameters:
    ///   - account: The account of the user to initialize crypto.
    ///   - cryptographicState: The account's cryptographic state.
    ///   - method: The crypto initialization method.
    func initializeUserCrypto(
        account: Account,
        cryptographicState: WrappedAccountCryptographicState,
        method: InitUserCryptoMethod,
    ) async throws {
        try await initializeUserCrypto(
            req: InitUserCryptoRequest(
                userId: account.profile.userId,
                kdfParams: account.kdf.sdkKdf,
                email: account.profile.email,
                accountCryptographicState: cryptographicState,
                method: method,
                upgradeToken: nil,
            ),
        )
    }
}
