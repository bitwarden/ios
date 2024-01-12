// MARK: - LoginTOTPState

/// A model defining the state of a TOTP key/code pair along with a TimeProvider to calculate expiration.
///
struct LoginTOTPState: Equatable {
    /// The auth key model used to generate TOTP codes.
    ///
    let authKeyModel: TOTPKeyModel

    /// The current TOTP code for the Login Item.
    ///
    var codeModel: TOTPCodeModel?

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
        self.authKeyModel = authKeyModel
        self.codeModel = codeModel
    }

    /// Optionally Initializes a LoginTOTPState model without a current code.
    ///
    /// - Parameters:
    ///   - authKeyModel: The optional TOTP key model.
    ///
    init?(_ authKeyModel: TOTPKeyModel?) {
        guard let authKeyModel else { return nil }
        self.authKeyModel = authKeyModel
        codeModel = nil
    }
}
