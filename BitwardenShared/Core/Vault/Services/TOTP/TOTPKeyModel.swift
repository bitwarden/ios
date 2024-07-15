/// A model representing  a TOTP authentication key.
///
public struct TOTPKeyModel: Equatable, Sendable {
    // MARK: Properties

    /// The authenticatorKey used to generate the `TOTPCodeConfig`.
    let rawAuthenticatorKey: String

    /// The key type used for generating the TOTP code.
    let totpKey: TOTPKey

    /// The hash algorithm used for the TOTP code.
    var algorithm: TOTPCryptoHashAlgorithm {
        totpKey.algorithm
    }

    /// The base 32 key used to generate the TOTP code.
    var base32Key: String {
        totpKey.base32Key
    }

    /// The number of digits in the TOTP code.
    var digits: Int {
        totpKey.digits
    }

    /// The time period (in seconds) for which the TOTP code is valid.
    var period: Int {
        totpKey.period
    }

    // MARK: Initializers

    /// Initializes a new configuration from an authenticator key.
    ///
    /// - Parameter authenticatorKey: A string representing the TOTP key.
    init(authenticatorKey: String) {
        rawAuthenticatorKey = authenticatorKey
        totpKey = TOTPKey(authenticatorKey)
    }
}
