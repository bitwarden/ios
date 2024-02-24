// MARK: - LoginTOTPState

/// A model defining the state of a TOTP key/code pair along with a TimeProvider to calculate expiration.
///
public enum LoginTOTPState: Equatable {
    /// A case with a code and key pair.
    case codeKeyPair(_ code: TOTPCodeModel, key: TOTPKeyModel)

    /// A case with an invalid key string.
    case invalid(_ keyString: String)

    /// A case with only a key.
    case key(_ key: TOTPKeyModel)

    /// A case with no code or key.
    case none

    /// The auth key model used to generate TOTP codes.
    ///
    var authKeyModel: TOTPKeyModel? {
        switch self {
        case let .codeKeyPair(_, key),
             let .key(key):
            return key
        case .invalid,
             .none:
            return nil
        }
    }

    /// The current TOTP code for the Login Item.
    ///
    var codeModel: TOTPCodeModel? {
        switch self {
        case let .codeKeyPair(code, _):
            return code
        case .invalid,
             .key,
             .none:
            return nil
        }
    }

    /// The raw key string
    ///
    var rawAuthenticatorKeyString: String? {
        switch self {
        case let .codeKeyPair(_, key),
             let .key(key):
            return key.rawAuthenticatorKey
        case let .invalid(rawInvalidKey):
            return rawInvalidKey
        case .none:
            return nil
        }
    }

    /// Initializes a LoginTOTPState model.
    ///
    /// - Parameters:
    ///   - authKeyModel: The TOTP key model.
    ///   - codeModel: The TOTP code model. Defaults to `nil`.
    ///
    init(
        authKeyModel: TOTPKeyModel,
        codeModel: TOTPCodeModel? = nil
    ) {
        if let code = codeModel {
            self = .codeKeyPair(code, key: authKeyModel)
        } else {
            self = .key(authKeyModel)
        }
    }

    /// Initializes a LoginTOTPState model without a current code.
    ///
    /// - Parameters:
    ///   - keyModel: The optional TOTP key model.
    ///
    init(keyModel: TOTPKeyModel?) {
        switch keyModel {
        case let .some(model):
            self = .key(model)
        case .none:
            self = .none
        }
    }

    /// Initializes a LoginTOTPState model from a possible TOTP Auth Key String
    ///
    /// - Parameters:
    ///   - authKeyString: The optional TOTP key string.
    ///
    init(_ authKeyString: String?) {
        switch authKeyString {
        case let .some(string):
            if let model = TOTPKeyModel(authenticatorKey: string) {
                self = .key(model)
            } else if !string.isEmpty {
                self = .invalid(string)
            } else {
                self = .none
            }
        case .none:
            self = .none
        }
    }
}
