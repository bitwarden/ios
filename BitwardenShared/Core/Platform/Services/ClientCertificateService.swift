import BitwardenKit
import BitwardenResources
import CryptoKit
import Foundation
import Security

// MARK: - ClientCertificateService

/// A service for managing client certificates used for mTLS authentication.
///
protocol ClientCertificateService: AnyObject { // sourcery: AutoMockable
    /// Import a client certificate from PKCS#12 data.
    ///
    /// Parses the certificate, stores the identity in the Keychain, and returns the SHA-256
    /// fingerprint of the imported certificate.
    ///
    /// - Parameters:
    ///   - data: The PKCS#12 certificate data.
    ///   - password: The password for the certificate.
    ///   - alias: The human-readable label to associate with the certificate.
    /// - Returns: The SHA-256 fingerprint of the imported certificate.
    /// - Throws: An error if the certificate cannot be imported.
    ///
    func importCertificate(
        data: Data,
        password: String,
        alias: String,
    ) async throws -> String

    /// Removes the client certificate with the given fingerprint from the Keychain if no other
    /// account still references it.
    ///
    /// - Parameter fingerprint: The SHA-256 fingerprint of the certificate to remove.
    ///
    /// sourcery: useSelectorName
    func removeCertificate(fingerprint: String) async throws

    /// Removes the client certificate for a specific user account.
    ///
    /// Used during account logout to clean up certificate data. Reads the certificate fingerprint
    /// from the account's stored environment URLs and deletes the Keychain identity only if no
    /// other account still references it.
    ///
    /// - Parameter userId: The user ID of the account being removed.
    ///
    /// sourcery: useSelectorName
    func removeCertificate(userId: String) async throws

    /// Gets the client certificate identity for mTLS authentication from the current environment.
    ///
    /// The environment service determines which URLs are active (pre-auth or logged-in account),
    /// so this returns the correct certificate for the current context.
    ///
    /// - Returns: A `SecIdentity` for the certificate, or `nil` if none is configured.
    ///
    func getClientCertificateIdentity() async -> SecIdentity?
}

// MARK: - DefaultClientCertificateService

/// Default implementation of the `ClientCertificateService`.
///
final class DefaultClientCertificateService: ClientCertificateService {
    // MARK: Private Properties

    /// The service used to manage environment URLs (handles pre-auth vs active account).
    private let environmentService: EnvironmentService

    /// The repository used to store certificate data in the keychain.
    private let keychainRepository: KeychainRepository

    /// The service used to manage application state.
    private let stateService: StateService

    // MARK: Initialization

    /// Initialize a `DefaultClientCertificateService`.
    ///
    /// - Parameters:
    ///   - environmentService: The service used to manage environment URLs.
    ///   - keychainRepository: The repository used to store sensitive certificate data in the Keychain.
    ///   - stateService: The service used to manage application state.
    ///
    init(
        environmentService: EnvironmentService,
        keychainRepository: KeychainRepository,
        stateService: StateService,
    ) {
        self.environmentService = environmentService
        self.keychainRepository = keychainRepository
        self.stateService = stateService
    }

    // MARK: Methods

    func importCertificate(
        data: Data,
        password: String,
        alias: String,
    ) async throws -> String {
        let importOptions: [String: Any] = [
            kSecImportExportPassphrase as String: password,
        ]

        var importResult: CFArray?
        let status = SecPKCS12Import(data as CFData, importOptions as CFDictionary, &importResult)

        if status == errSecAuthFailed {
            throw ClientCertificateError.invalidPassword
        }

        guard status == errSecSuccess,
              let importArray = importResult as? [[String: Any]],
              let firstItem = importArray.first,
              let identityRef = firstItem[kSecImportItemIdentity as String] else {
            throw ClientCertificateError.invalidCertificate
        }

        // SecIdentity is a CoreFoundation type; use CFTypeRef bridge instead of conditional cast.
        let identity = identityRef as! SecIdentity // swiftlint:disable:this force_cast
        let fingerprint = try certificateFingerprint(for: identity)

        // Only add to Keychain if this certificate isn't already stored.
        // Multiple users may share the same certificate — keyed by fingerprint, not userId.
        let existing = try await keychainRepository.getClientCertificateIdentity(fingerprint: fingerprint)
        if existing == nil {
            try await keychainRepository.setClientCertificateIdentity(identity, fingerprint: fingerprint)
        }

        return fingerprint
    }

    func removeCertificate(fingerprint: String) async throws {
        // Only delete the Keychain item if no other account still references this certificate.
        let inUse = await isFingerprintInUse(fingerprint)
        if !inUse {
            try await keychainRepository.deleteClientCertificateIdentity(fingerprint: fingerprint)
        }
    }

    func removeCertificate(userId: String) async throws {
        // Read the fingerprint from the account's stored environment URLs.
        let environmentURLs = try? await stateService.getEnvironmentURLs(userId: userId)
        let fingerprint = environmentURLs?.clientCertificateFingerprint

        guard let fingerprint else { return }

        // Only delete the Keychain item if no other account still references this certificate.
        let inUse = await isFingerprintInUse(fingerprint, excludingUserId: userId)
        if !inUse {
            try await keychainRepository.deleteClientCertificateIdentity(fingerprint: fingerprint)
        }
    }

    func getClientCertificateIdentity() async -> SecIdentity? {
        guard let fingerprint = environmentService.clientCertificateFingerprint,
              !fingerprint.isEmpty else {
            return nil
        }
        return try? await keychainRepository.getClientCertificateIdentity(fingerprint: fingerprint)
    }

    // MARK: Private

    /// Computes the SHA-256 fingerprint of the certificate within a SecIdentity.
    ///
    private func certificateFingerprint(for identity: SecIdentity) throws -> String {
        var certificate: SecCertificate?
        let status = SecIdentityCopyCertificate(identity, &certificate)
        guard status == errSecSuccess, let cert = certificate else {
            throw ClientCertificateError.invalidCertificate
        }
        let data = SecCertificateCopyData(cert) as Data
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Returns whether any account's environment URLs still reference the given fingerprint.
    ///
    /// - Parameters:
    ///   - fingerprint: The certificate fingerprint to check.
    ///   - excludingUserId: An optional user ID to exclude from the check (e.g., the account being removed).
    ///
    private func isFingerprintInUse(_ fingerprint: String, excludingUserId: String? = nil) async -> Bool {
        // Check the pre-auth environment URLs.
        let preAuthURLs = await stateService.getPreAuthEnvironmentURLs()
        if preAuthURLs?.clientCertificateFingerprint == fingerprint {
            return true
        }

        // Check all regular accounts' environment URLs.
        let accounts = await (try? stateService.getAccounts()) ?? []
        for account in accounts {
            let accountUserId = account.profile.userId
            if let excludingUserId, accountUserId == excludingUserId { continue }
            let accountURLs = try? await stateService.getEnvironmentURLs(userId: accountUserId)
            if accountURLs?.clientCertificateFingerprint == fingerprint { return true }
        }

        return false
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
            Localizations.theCertificateFileIsInvalidOrCorrupted
        case .invalidPassword:
            Localizations.theCertificatePasswordIsIncorrect
        case .certificateExpired:
            Localizations.theCertificateHasExpired
        }
    }
}
