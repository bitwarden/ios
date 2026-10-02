import BitwardenSdk
import Foundation

/// A protocol for a service that handles SDK-managed user crypto state tasks. This is similar to
/// `UserCryptoManagementClientProtocol` but returns protocols so they can be mocked for testing.
///
public protocol UserCryptoManagementClientService: AnyObject, Sendable { // sourcery: AutoMockable
    /// Changes the user's KDF settings.
    ///
    func changeKdf(password: String, newKdf: Kdf) async throws

    /// Returns the PIN settings sub-client.
    ///
    func pinSettings() -> PinSettingsClientProtocol

    /// Backfills the server with the id of the user's current user key, if missing.
    ///
    func userKeyIdBackfill() async throws
}

// MARK: UserCryptoManagementClient

extension UserCryptoManagementClient: UserCryptoManagementClientService {
    public func pinSettings() -> PinSettingsClientProtocol {
        pinSettings() as PinSettingsClient
    }
}
