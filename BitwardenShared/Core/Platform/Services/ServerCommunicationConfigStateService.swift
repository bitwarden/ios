import BitwardenKit
import BitwardenSdk
import Foundation

// MARK: - ServerCommunicationConfigStateService

/// A service that provides state management functionality for the server communication configuration.
///
protocol ServerCommunicationConfigStateService { // sourcery: AutoMockable
    /// Gets the server communication configuration for a given hostname.
    ///
    /// - Parameter hostname: The hostname associated with the server communication config.
    /// - Returns: The server communication config for that hostname.
    ///
    func getServerCommunicationConfig(hostname: String) async throws -> BitwardenSdk.ServerCommunicationConfig?

    /// Sets the server communication config for a given hostname.
    ///
    /// - Parameters:
    ///   - config: The server communication config.
    ///   - hostname: The hostname associated with the config.
    ///
    func setServerCommunicationConfig(_ config: BitwardenSdk.ServerCommunicationConfig?, hostname: String) async throws
}

// MARK: Server Communication Config

extension DefaultStateService: ServerCommunicationConfigStateService {
    func clearServerCommunicationCookieValue(hostname: String) async throws {
        guard let config = try await keychainRepository.getServerCommunicationConfig(hostname: hostname),
              case let .ssoCookieVendor(vendorConfig) = config.bootstrap else {
            return
        }
        let clearedConfig = ServerCommunicationConfig(
            bootstrap: .ssoCookieVendor(
                SsoCookieVendorConfig(
                    idpLoginUrl: vendorConfig.idpLoginUrl,
                    cookieName: vendorConfig.cookieName,
                    cookieDomain: vendorConfig.cookieDomain,
                    vaultUrl: vendorConfig.vaultUrl,
                    cookieValue: nil,
                ),
            ),
        )
        try await keychainRepository.setServerCommunicationConfig(clearedConfig, hostname: hostname)
    }

    func getServerCommunicationConfig(hostname: String) async throws -> BitwardenSdk.ServerCommunicationConfig? {
        do {
            return try await keychainRepository.getServerCommunicationConfig(hostname: hostname)
        } catch KeychainServiceError.osStatusError(errSecItemNotFound) {
            return nil
        }
    }

    func setServerCommunicationConfig(
        _ config: BitwardenSdk.ServerCommunicationConfig?,
        hostname: String,
    ) async throws {
        try await keychainRepository.setServerCommunicationConfig(config, hostname: hostname)
    }
}
