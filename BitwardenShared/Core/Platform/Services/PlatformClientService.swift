import BitwardenSdk
import Foundation

/// A protocol for a service that handles platform tasks. This is similar to
/// `PlatformClientProtocol` but returns the protocols so they can be mocked for testing.
///
protocol PlatformClientService: AnyObject {
    /// Returns an object to handle Fido2 operations.
    func fido2() -> ClientFido2Service

    /// Gets the fingerprint (public key) based on `req`.
    /// - Parameter request: Request with parameters for the fingerprint.
    /// - Returns: Fingerprint pubilc key.
    func fingerprint(request req: FingerprintRequest) throws -> String

    /// Load feature flags into the client.
    /// - Parameter flags: Flags to load.
    func loadFlags(_ flags: [String: Bool]) throws

    /// Returns an object to handle state.
    func state() -> StateClientProtocol

    /// Fingerprint using logged in user's public key
    /// - Parameter material: Fingerprint material to use
    /// - Returns: User fingerprint
    func userFingerprint(material fingerprintMaterial: String) throws -> String
}

// MARK: PlatformClient

extension PlatformClient: PlatformClientService {
    func fido2() -> ClientFido2Service {
        fido2() as ClientFido2
    }

    func fingerprint(request req: FingerprintRequest) throws -> String {
        try fingerprint(req: req)
    }

    func loadFlags(_ flags: [String: Bool]) throws {
        try loadFlags(flags: flags)
    }

    func state() -> StateClientProtocol {
        state() as StateClient
    }

    func userFingerprint(material fingerprintMaterial: String) throws -> String {
        try userFingerprint(fingerprintMaterial: fingerprintMaterial)
    }
}
