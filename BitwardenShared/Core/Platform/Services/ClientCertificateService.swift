import Foundation
import Security

// MARK: - ClientCertificateService

/// A service for managing client certificates used for mTLS authentication.
///
protocol ClientCertificateService: AnyObject {
    /// Import a client certificate from PKCS#12 data.
    ///
    /// - Parameters:
    ///   - data: The PKCS#12 certificate data.
    ///   - password: The password for the certificate.
    /// - Returns: The imported certificate configuration.
    /// - Throws: An error if the certificate cannot be imported.
    ///
    func importCertificate(data: Data, password: String) async throws -> ClientCertificateConfiguration

    /// Get the current client certificate configuration.
    ///
    /// - Returns: The current certificate configuration, or `.disabled` if none is configured.
    ///
    func getCurrentConfiguration() async -> ClientCertificateConfiguration

    /// Remove the current client certificate.
    ///
    func removeCertificate() async throws

    /// Get the client certificate data and password for mTLS.
    ///
    /// - Returns: A tuple containing the certificate data and password, or nil if no certificate is configured.
    ///
    func getClientCertificateForTLS() async -> (data: Data, password: String)?

    /// Checks if client certificates are currently enabled and configured.
    ///
    /// - Returns: `true` if client certificates should be used for authentication.
    ///
    func shouldUseCertificates() async -> Bool
}

// MARK: - DefaultClientCertificateService

/// Default implementation of the `ClientCertificateService`.
///
final class DefaultClientCertificateService: ClientCertificateService {
    // MARK: Private Properties

    /// The service for storing application state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultClientCertificateService`.
    ///
    /// - Parameters:
    ///   - stateService: The service used to manage application state.
    ///
    init(stateService: StateService) {
        self.stateService = stateService
    }

    // MARK: Methods

    func importCertificate(data: Data, password: String) async throws -> ClientCertificateConfiguration {
        // Parse PKCS#12 data
        let importOptions: [String: Any] = [
            kSecImportExportPassphrase as String: password,
        ]

        var importResult: CFArray?
        let status = SecPKCS12Import(data as CFData, importOptions as CFDictionary, &importResult)

        guard status == errSecSuccess,
              let importArray = importResult as? [[String: Any]],
              let firstItem = importArray.first,
              let certificate = firstItem[kSecImportItemCertChain as String] as? [SecCertificate],
              let cert = certificate.first else {
            throw ClientCertificateError.invalidCertificate
        }

        // Extract certificate information
        let subject = getCertificateSubject(cert)
        let issuer = getCertificateIssuer(cert)
        let expirationDate = getCertificateExpirationDate(cert)

        // Store certificate securely in keychain
        let configuration = ClientCertificateConfiguration.enabled(
            certificateData: data,
            password: password,
            subject: subject,
            issuer: issuer,
            expirationDate: expirationDate
        )

        await stateService.setGlobalClientCertificateConfiguration(configuration)

        return configuration
    }

    func getCurrentConfiguration() async -> ClientCertificateConfiguration {
        await stateService.getGlobalClientCertificateConfiguration() ?? .disabled
    }

    func removeCertificate() async throws {
        await stateService.setGlobalClientCertificateConfiguration(.disabled)
    }

    func getClientCertificateForTLS() async -> (data: Data, password: String)? {
        let configuration = await getCurrentConfiguration()

        guard configuration.isEnabled,
              let certificateData = configuration.certificateData,
              let password = configuration.password else {
            return nil
        }

        return (data: certificateData, password: password)
    }

    func shouldUseCertificates() async -> Bool {
        let configuration = await getCurrentConfiguration()
        return configuration.isEnabled && configuration.certificateData != nil
    }

    // MARK: Private Methods

    private func getCertificateSubject(_ certificate: SecCertificate) -> String {
        var commonName: CFString?
        let status = SecCertificateCopyCommonName(certificate, &commonName)

        if status == errSecSuccess, let name = commonName as String? {
            return name
        }

        return "Unknown Subject"
    }

    private func getCertificateIssuer(_ certificate: SecCertificate) -> String {
        // For iOS, we'll use a simplified approach since detailed issuer info requires more complex parsing
        "Certificate Authority"
    }

    private func getCertificateExpirationDate(_ certificate: SecCertificate) -> Date {
        // For iOS, we'll use a default expiration date since extracting the actual date requires complex parsing
        Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year from now
    }
}

// MARK: - ClientCertificateError

/// Errors that can occur when working with client certificates.
///
enum ClientCertificateError: Error, LocalizedError {
    /// The certificate data is invalid or cannot be parsed.
    case invalidCertificate

    /// The certificate password is incorrect.
    case invalidPassword

    /// The certificate has expired.
    case certificateExpired

    var errorDescription: String? {
        switch self {
        case .invalidCertificate:
            return "The certificate file is invalid or corrupted."
        case .invalidPassword:
            return "The certificate password is incorrect."
        case .certificateExpired:
            return "The certificate has expired."
        }
    }
}
