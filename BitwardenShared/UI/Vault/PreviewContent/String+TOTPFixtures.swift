#if DEBUG
extension String {
    static let standardTotpKey = "JBSWY3DPEHPK3PXP"
    static let standardTotpKeyWithSpaces = "JBSWY 3DPEHP K3PXP"
    // swiftlint:disable:next line_length
    static let otpAuthUriKeyComplete = "otpauth://totp/Example:user@bitwarden.com?secret=JBSWY3DPEHPK3PXP&issuer=Example&algorithm=SHA256&digits=6&period=30"
    static let otpAuthUriKeyMinimum = "otpauth://totp/:?secret=JBSWY3DPEHPK3PXP"
    static let otpAuthUriKeyNonBase32 = "otpauth://totp/:?secret=1234567890"
    static let otpAuthUriKeyPartial = "otpauth://totp/Example:user@bitwarden.com?secret=JBSWY3DPEHPK3PXP"
    // swiftlint:disable:next line_length
    static let otpAuthUriKeySHA512 = "otpauth://totp/Example:user@bitwarden.com?secret=JBSWY3DPEHPK3PXP&algorithm=SHA512"
    static let steamUriKeyIdentifier = "JBSWY3DPEHPK3PXP"
    static let steamUriKey = "steam://\(steamUriKeyIdentifier)"
}

extension OTPAuthModel {
    static let fixtureExample = OTPAuthModel(otpAuthKey: .otpAuthUriKeyComplete)!
    static let fixtureMinimum = OTPAuthModel(otpAuthKey: .otpAuthUriKeyMinimum)!
}
#endif
