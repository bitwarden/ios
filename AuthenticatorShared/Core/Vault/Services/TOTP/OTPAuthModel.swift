import Foundation

// MARK: - OTPAuthModel

/// Model representing the components extracted from an OTP Auth URI
/// as defined by https://github.com/google/google-authenticator/wiki/Key-Uri-Format
///
struct OTPAuthModel: Equatable {
    // MARK: Properties

    /// The username or email associated with this account.
    /// The google spec suggests this is required, but is optional in the google app.
    let accountName: String?

    /// The hashing algorithm used for generating the OTP.
    let algorithm: TOTPCryptoHashAlgorithm

    /// The number of digits in the OTP. Default is 6.
    let digits: Int

    /// The provider or service the account is associated with.
    let issuer: String?

    /// The time period in seconds for which the OTP is valid. Default is 30.
    let period: Int

    /// An arbitrary key value encoded in Base 32, used to generate the OTP.
    let secret: String

    /// A standardized (with all parameters) OTP Auth URI representing this model.
    var otpAuthUri: String {
        let label: String
        let issuerParameter: String
        switch (issuer, accountName) {
        case let (.some(issuer), .some(accountName)):
            label = "\(issuer):\(accountName)"
            issuerParameter = "&issuer=\(issuer)"
        case let (.some(issuer), .none):
            label = ""
            issuerParameter = "&issuer=\(issuer)"
        case let (.none, .some(accountName)):
            label = "\(accountName)"
            issuerParameter = ""
        case (.none, .none):
            label = ""
            issuerParameter = ""
        }

        // swiftlint:disable:next line_length
        return "otpauth://totp/\(label)?secret=\(secret)\(issuerParameter)&algorithm=\(algorithm.rawValue)&digits=\(digits)&period=\(period)"
    }

    // MARK: Initialization

    /// Initializes a new instance of `OTPAuthModel` by components
    ///
    /// - Parameters:
    ///   - accountName: The username associated with the account
    ///   - algorithm: The hashing algorithm to use
    ///   - digits: The number of digits in the code
    ///   - issuer: The provider or service of the account
    ///   - period: The length of time in seconds an OTP is valid
    ///   - secret: The key value, encoded in Base 32
    init(
        accountName: String?,
        algorithm: TOTPCryptoHashAlgorithm,
        digits: Int,
        issuer: String?,
        period: Int,
        secret: String
    ) {
        self.accountName = accountName
        self.algorithm = algorithm
        self.digits = digits
        self.issuer = issuer
        self.period = period
        self.secret = secret
    }

    /// Parses an OTP Auth URI into its components.
    ///
    /// - Parameters:
    ///   - otpAuthUri: The OTP Auth URI as a string
    init?(otpAuthUri: String) {
        guard let urlComponents = URLComponents(string: otpAuthUri),
              urlComponents.scheme == "otpauth",
              urlComponents.host == "totp",
              let queryItems = urlComponents.queryItems,
              let secret = queryItems.first(where: { $0.name == "secret" })?.value,
              secret.uppercased().isBase32
        else {
            return nil
        }

        let algorithm = TOTPCryptoHashAlgorithm(from: queryItems.first { $0.name == "algorithm" }?.value)
        let digits = queryItems.first { $0.name == "digits" }?.value.flatMap(Int.init) ?? 6
        let issuer = queryItems.first { $0.name == "issuer" }?.value
        let period = queryItems.first { $0.name == "period" }?.value.flatMap(Int.init) ?? 30

        let labelComponents = urlComponents.path.dropFirst().split(separator: ":")

        let accountName: String?
        let labelIssuer: String?

        switch labelComponents.count {
        case 0:
            accountName = nil
            labelIssuer = nil
        case 1:
            accountName = String(labelComponents[0])
            labelIssuer = nil
        case 2:
            accountName = String(labelComponents[1])
            labelIssuer = String(labelComponents[0])
        default:
            return nil
        }

        self.init(
            accountName: accountName,
            algorithm: algorithm,
            digits: digits,
            issuer: issuer ?? labelIssuer,
            period: period,
            secret: secret
        )
    }
}
