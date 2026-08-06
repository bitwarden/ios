import BitwardenKit
import BitwardenSdk

final class SdkServerCommunicationConfigRepository: ServerCommunicationConfigRepository {
    // MARK: Properties

    /// The service that provides state management functionality for the
    /// server communication configuration.
    private let serverCommunicationConfigStateService: ServerCommunicationConfigStateService

    // MARK: Init

    /// Initializes a `SdkServerCommunicationConfigRepository`
    /// - Parameters:
    ///   - serverCommunicationConfigStateService: The service that provides state management functionality for the
    /// server communication configuration.
    init(serverCommunicationConfigStateService: ServerCommunicationConfigStateService) {
        self.serverCommunicationConfigStateService = serverCommunicationConfigStateService
    }

    // MARK: Methods

    func get(domain: String) async throws -> BitwardenSdk.ServerCommunicationConfig? {
        try await serverCommunicationConfigStateService.getServerCommunicationConfig(hostname: domain)
    }

    func save(domain: String, config: BitwardenSdk.ServerCommunicationConfig) async throws {
        let localConfig = try await serverCommunicationConfigStateService.getServerCommunicationConfig(
            hostname: domain,
        )
        guard let localConfig else {
            try await serverCommunicationConfigStateService.setServerCommunicationConfig(config, hostname: domain)
            return
        }

        let updatedConfig = localConfig.updateCookieValue(from: config)
        try await serverCommunicationConfigStateService.setServerCommunicationConfig(
            updatedConfig,
            hostname: domain,
        )
    }
}
