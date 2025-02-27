/// Defines the hash algorithms supported for TOTP.
///
enum TOTPCryptoHashAlgorithm: String, Menuable, CaseIterable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"

    var localizedName: String {
        rawValue
    }

    /// Initializes the algorithm from a given string value.
    /// - Parameter rawValue: An optional `String`.
    ///
    init(from rawValue: String?) {
        switch rawValue?.uppercased() {
        case "SHA256":
            self = .sha256
        case "SHA512":
            self = .sha512
        default: // Default to SHA1 if not specified or unrecognized
            self = .sha1
        }
    }
}
