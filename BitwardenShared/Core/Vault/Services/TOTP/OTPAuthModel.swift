import Foundation

/// Model representing the components extracted from an OTP Auth URI.
///
/// This model includes the Base32-encoded key, the period, the number of digits, and the hashing algorithm.
struct OTPAuthModel: Equatable {
    /// The Base32-encoded key used for generating the OTP.
    let keyB32: String

    /// The time period in seconds for which the OTP is valid.
    let period: Int

    /// The number of digits in the OTP.
    let digits: Int

    /// The hashing algorithm used for generating the OTP.
    let algorithm: TOTPCryptoHashAlgorithm

    /// Initializes a new instance of `OTPAuthModel`.
    ///
    /// - Parameters:
    ///   - keyB32: The Base32-encoded key.
    ///   - period: The time period in seconds for which the OTP is valid.
    ///   - digits: The number of digits in the OTP.
    ///   - algorithm: The hashing algorithm used for generating the OTP.
    init(keyB32: String, period: Int, digits: Int, algorithm: TOTPCryptoHashAlgorithm) {
        self.keyB32 = keyB32
        self.period = period
        self.digits = digits
        self.algorithm = algorithm
    }

    /// Parses an OTP Auth URI into its components.
    ///
    /// - Parameter otpAuthKey: A string representing the OTP Auth URI.
    ///
    init?(otpAuthKey: String) {
        guard let urlComponents = URLComponents(string: otpAuthKey.lowercased()),
              urlComponents.scheme == "otpauth",
              let queryItems = urlComponents.queryItems,
              let secret = queryItems.first(where: { $0.name == "secret" })?.value else {
            return nil
        }

        let period = queryItems.first { $0.name == "period" }?.value.flatMap(Int.init) ?? 30
        let digits = queryItems.first { $0.name == "digits" }?.value.flatMap(Int.init) ?? 6
        let algorithm = TOTPCryptoHashAlgorithm(from: queryItems.first { $0.name == "algorithm" }?.value)

        self.init(keyB32: secret, period: period, digits: digits, algorithm: algorithm)
    }
}
