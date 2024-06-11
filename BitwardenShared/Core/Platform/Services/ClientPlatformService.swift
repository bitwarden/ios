import BitwardenSdk
import Foundation

/// A protocol for a service that handles platform tasks. This is similar to
/// `ClientPlatformProtocol` but returns the protocols so they can be mocked for testing.
///
protocol ClientPlatformService: AnyObject {
    /// Returns an object to handle Fido2 operations.
    func fido2() -> ClientFido2Service

    /// Gets the fingerprint (public key) based on `req`.
    /// - Parameter request: Request with parameters for the fingerprint.
    /// - Returns: Fingerprint pubilc key.
    func fingerprint(request req: FingerprintRequest) async throws -> String

    /// Load feature flags into the client.
    /// - Parameter flags: Flags to load.
    func loadFlags(_ flags: [String: Bool]) async throws

    /// Fingerprint using logged in user's public key
    /// - Parameter material: Fingerprint material to use
    /// - Returns: User fingerprint
    func userFingerprint(material fingerprintMaterial: String) async throws -> String
}

// MARK: ClientPlatform

extension ClientPlatform: ClientPlatformService {
    func fido2() -> ClientFido2Service {
        fido2() as ClientFido2
    }

    func fingerprint(request req: FingerprintRequest) async throws -> String {
        try await fingerprint(req: req)
    }

    func loadFlags(_ flags: [String: Bool]) async throws {
        try await loadFlags(flags: flags)
    }

    func userFingerprint(material fingerprintMaterial: String) async throws -> String {
        try await userFingerprint(fingerprintMaterial: fingerprintMaterial)
    }
}
