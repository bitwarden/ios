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

    /// The model used to provide time for a TOTP code expiration check.
    ///
    let totpTime: TOTPTime

    /// Initializes a LoginTOTPState model.
    ///
    /// - Parameters:
    ///   - authKeyModel: The TOTP key model.
    ///   - codeModel: The TOTP code model. Defaults to `nil`.
    ///   - totpTime: The TimeProvider used to calculate code expiration.
    ///
    init(
        authKeyModel: TOTPKeyModel,
        codeModel: TOTPCodeModel? = nil,
        totpTime: TOTPTime
    ) {
        self.authKeyModel = authKeyModel
        self.codeModel = codeModel
        self.totpTime = totpTime
    }

    /// Optionally Initializes a LoginTOTPState model without a current code.
    ///
    /// - Parameters:
    ///   - authKeyModel: The optional TOTP key model.
    ///   - totpTime: The TimeProvider used to calculate code expiration.
    ///
    init?(_ authKeyModel: TOTPKeyModel?, time: TOTPTime) {
        guard let authKeyModel else { return nil }
        self.authKeyModel = authKeyModel
        codeModel = nil
        totpTime = time
    }
}
