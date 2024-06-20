import Foundation

/// Model representing the components extracted from an OTP Auth URI.
///
/// This model includes the Base32-encoded key, the period, the number of digits, and the hashing algorithm.
public struct OTPAuthModel: Equatable, Hashable, Sendable {
    // MARK: Properties

    /// The name of the account for the key.
    let accountName: String?

    /// The hashing algorithm used for generating the OTP.
    let algorithm: TOTPCryptoHashAlgorithm

    /// The number of digits in the OTP.
    let digits: Int

    /// The provider or service the account is associated with.
    let issuer: String?

    /// The Base32-encoded key used for generating the OTP.
    let keyB32: String

    /// The time period in seconds for which the OTP is valid.
    let period: Int

    /// The unparsed key URI.
    let uri: String

    // MARK: Initialization

    /// Initializes a new instance of `OTPAuthModel`.
    ///
    /// - Parameters:
    ///   - account: The name of the account for the key.
    ///   - algorithm: The hashing algorithm used for generating the OTP.
    ///   - digits: The number of digits in the OTP.
    ///   - issuer: The provider or service the account is associated with.
    ///   - keyB32: The Base32-encoded key.
    ///   - period: The time period in seconds for which the OTP is valid.
    ///   - uri: The unparsed key URI.
    ///
    init(
        accountName: String? = nil,
        algorithm: TOTPCryptoHashAlgorithm,
        digits: Int,
        issuer: String? = nil,
        keyB32: String,
        period: Int,
        uri: String
    ) {
        self.accountName = accountName
        self.algorithm = algorithm
        self.digits = digits
        self.issuer = issuer
        self.keyB32 = keyB32
        self.period = period
        self.uri = uri
    }

    /// Parses an OTP Auth URI into its components.
    ///
    /// - Parameter otpAuthKey: A string representing the OTP Auth URI.
    ///
    init?(otpAuthKey: String) {
        guard let urlComponents = URLComponents(string: otpAuthKey),
              urlComponents.scheme == "otpauth",
              let queryItems = urlComponents.queryItems,
              let secret = queryItems.first(where: { $0.name == "secret" })?.value,
              secret.uppercased().isBase32 else {
            return nil
        }

        let algorithm = TOTPCryptoHashAlgorithm(from: queryItems.first { $0.name == "algorithm" }?.value)
        let digits = queryItems.first { $0.name == "digits" }?.value.flatMap(Int.init) ?? 6
        var issuer = queryItems.first { $0.name == "issuer" }?.value
        let period = queryItems.first { $0.name == "period" }?.value.flatMap(Int.init) ?? 30

        var accountName: String?
        if let label = urlComponents.url?.lastPathComponent {
            let parts = label.split(separator: ":")
            if parts.count > 1 {
                issuer = issuer ?? String(parts[0])
                accountName = String(parts[1])
            } else {
                accountName = label
            }
        }

        self.init(
            accountName: accountName,
            algorithm: algorithm,
            digits: digits,
            issuer: issuer,
            keyB32: secret,
            period: period,
            uri: otpAuthKey
        )
    }
}
