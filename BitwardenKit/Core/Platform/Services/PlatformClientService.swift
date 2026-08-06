import BitwardenSdk
import Foundation

/// A protocol for a service that handles platform tasks. This is similar to
/// `PlatformClientProtocol` but returns the protocols so they can be mocked for testing.
///
public protocol PlatformClientService: AnyObject { // sourcery: AutoMockable
    /// Returns an object to handle Fido2 operations.
    func fido2() -> ClientFido2Service

    /// Gets the fingerprint (public key) based on `req`.
    /// - Parameter req: Request with parameters for the fingerprint.
    /// - Returns: Fingerprint public key.
    func fingerprint(req: FingerprintRequest) throws -> String

    /// Load feature flags into the client.
    /// - Parameter flags: Flags to load.
    func loadFlags(flags: [String: Bool]) async throws

    /// Server communication configuration operations.
    /// - Parameters:
    ///   - repository: The repository to use for server communication operations.
    ///   - platformApi: The platform API to use for server communication operations.
    /// - Returns: A server communication client to interact with.
    func serverCommunicationConfig(
        repository: ServerCommunicationConfigRepository,
        platformApi: ServerCommunicationConfigPlatformApi,
    ) -> ServerCommunicationConfigClientProtocol

    /// Returns an object to handle state.
    func state() -> StateClientProtocol

    /// Fingerprint using logged in user's public key
    /// - Parameter fingerprintMaterial: Fingerprint material to use
    /// - Returns: User fingerprint
    func userFingerprint(fingerprintMaterial: String) throws -> String
}

// MARK: PlatformClient

extension PlatformClient: PlatformClientService {
    public func fido2() -> ClientFido2Service {
        fido2() as ClientFido2
    }

    public func serverCommunicationConfig(
        repository: ServerCommunicationConfigRepository,
        platformApi: ServerCommunicationConfigPlatformApi,
    ) -> ServerCommunicationConfigClientProtocol {
        let client: ServerCommunicationConfigClient = serverCommunicationConfig(
            repository: repository,
            platformApi: platformApi,
        )
        return client
    }

    public func state() -> StateClientProtocol {
        state() as StateClient
    }
}
