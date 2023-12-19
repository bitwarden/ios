/// Extension on `String` to provide utilities for TOTP key validation.
///
/// Includes checks for Base32 encoded strings, OTP Auth URIs, and Steam URIs.
///
extension String {
    /// `true` if the String is base 32.
    var isBase32: Bool {
        let regex = "^[A-Z2-7]+=*$"
        return range(of: regex, options: .regularExpression) != nil
    }

    /// `true` if prefixed with `steam://` and followed by a base 32 string.
    var isSteamUri: Bool {
        guard let keyIndexOffset = steamURIKeyIndexOffset else {
            return false
        }
        let key = String(suffix(from: keyIndexOffset))
        return key.isBase32
    }

    /// `true` if the String begins with "otpauth://"
    var hasOTPAuthPrefix: Bool {
        lowercased().starts(with: "otpauth://")
    }

    var steamURIKeyIndexOffset: String.Index? {
        guard lowercased().starts(with: "steam://") else { return nil }
        return index(startIndex, offsetBy: 8)
    }
}
