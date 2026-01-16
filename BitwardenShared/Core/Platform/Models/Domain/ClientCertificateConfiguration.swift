import Foundation

// MARK: - ClientCertificateConfiguration

/// Configuration for client certificate authentication.
///
struct ClientCertificateConfiguration: Codable, Equatable {
    // MARK: Type Properties

    /// Creates a disabled client certificate configuration.
    static let disabled = ClientCertificateConfiguration(
        isEnabled: false,
        certificateData: nil,
        password: nil,
        subject: nil,
        issuer: nil,
        expirationDate: nil
    )

    // MARK: Properties

    /// Whether client certificate authentication is enabled.
    let isEnabled: Bool

    /// The certificate data (PKCS#12 format).
    let certificateData: Data?

    /// The certificate password.
    let password: String?

    /// The certificate subject (for display purposes).
    let subject: String?

    /// The certificate issuer (for display purposes).
    let issuer: String?

    /// The certificate expiration date.
    let expirationDate: Date?

    // MARK: Type Methods

    /// Creates an enabled client certificate configuration.
    ///
    /// - Parameters:
    ///   - certificateData: The certificate data in PKCS#12 format.
    ///   - password: The certificate password.
    ///   - subject: The certificate subject.
    ///   - issuer: The certificate issuer.
    ///   - expirationDate: The certificate expiration date.
    ///
    static func enabled(
        certificateData: Data,
        password: String,
        subject: String,
        issuer: String,
        expirationDate: Date
    ) -> ClientCertificateConfiguration {
        ClientCertificateConfiguration(
            isEnabled: true,
            certificateData: certificateData,
            password: password,
            subject: subject,
            issuer: issuer,
            expirationDate: expirationDate
        )
    }
}
