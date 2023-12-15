/// Represents different types of TOTP keys.
///
enum TOTPKey: Equatable {
    /// A base 32 string key
    case base32(key: String)
    /// An OTP Auth URI
    case otpAuthUri(OTPAuthModel)
    /// A Steam URI
    case steamUri(key: String)

    // MARK: Properties

    /// The hash algorithm used for the TOTP code.
    /// For `otpAuthUri`, it extracts the algorithm from the model.
    /// Defaults to SHA1 for other types.
    ///
    var algorithm: TOTPCryptoHashAlgorithm {
        guard case let .otpAuthUri(model) = self else { return .sha1 }
        return model.algorithm
    }

    /// The number of digits in the TOTP code.
    /// Defaults to 6 for base32 and OTP Auth URIs, and 5 for Steam URIs.
    ///
    var digits: Int {
        switch self {
        case .base32:
            return 6
        case let .otpAuthUri(model):
            return model.digits
        case .steamUri:
            return 5
        }
    }

    /// The key used for generating the TOTP code.
    /// Directly returns the key for base32 and Steam URI.
    /// For `otpAuthUri`, extracts the key from the model.
    var base32Key: String {
        switch self {
        case let .base32(key),
             let .steamUri(key):
            return key
        case let .otpAuthUri(model):
            return model.keyB32
        }
    }

    /// The time period (in seconds) for which the TOTP code is valid.
    /// Defaults to 30 seconds for base32 and Steam URIs.
    /// For `otpAuthUri`, extracts the period from the model.
    var period: Int {
        switch self {
        case .base32:
            return 30
        case let .otpAuthUri(model):
            return model.period
        case .steamUri:
            return 30
        }
    }

    // MARK: Initializers

    /// Initializes a TOTPKey from a given string.
    ///
    /// This initializer supports creation of different types of TOTP keys based on the string format.
    /// It supports base32 keys, OTP Auth URIs, and Steam URIs.
    ///
    /// - Parameter key: A string representing the TOTP key.
    init?(_ key: String) {
        if key.isBase32 {
            self = .base32(key: key)
        } else if key.hasOTPAuthPrefix,
                  let otpAuthModel = OTPAuthModel(otpAuthKey: key) {
            self = .otpAuthUri(otpAuthModel)
        } else if key.isSteamUri {
            let keyIndexOffset = key.index(key.startIndex, offsetBy: 8)
            let steamKey = String(key.suffix(from: keyIndexOffset))
            self = .steamUri(key: steamKey)
        } else {
            return nil
        }
    }
}
