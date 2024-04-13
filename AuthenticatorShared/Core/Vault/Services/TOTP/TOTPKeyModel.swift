/// A model representing  a TOTP authentication key.
///
public struct TOTPKeyModel: Equatable, Sendable {
    // MARK: Properties

    /// The account name of the TOTP code.
    let accountName: String?

    /// The hash algorithm used for the TOTP code.
    ///
    let algorithm: TOTPCryptoHashAlgorithm

    /// The base 32 key used to generate the TOTP code.
    var base32Key: String {
        totpKey.base32Key
    }

    /// The number of digits in the TOTP code.
    ///
    let digits: Int

    /// The issuer of the TOTP code.
    let issuer: String?

    /// The time period (in seconds) for which the TOTP code is valid.
    ///
    let period: Int

    /// The authenticatorKey used to generate the `TOTPCodeConfig`.
    let rawAuthenticatorKey: String

    /// The key type used for generating the TOTP code.
    let totpKey: TOTPKey

    // MARK: Initializers

    /// Initializes a new configuration from an authenticator key.
    ///
    /// - Parameter authenticatorKey: A string representing the TOTP key.
    init?(authenticatorKey: String?) {
        guard let key = authenticatorKey,
              let keyType = TOTPKey(key) else { return nil }
        rawAuthenticatorKey = key
        totpKey = keyType
        accountName = keyType.accountName
        algorithm = keyType.algorithm
        digits = keyType.digits
        issuer = keyType.issuer
        period = keyType.period
    }
}
