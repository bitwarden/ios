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

    func get(hostname: String) async throws -> BitwardenSdk.ServerCommunicationConfig? {
        try await serverCommunicationConfigStateService.getServerCommunicationConfig(hostname: hostname)
    }

    func save(hostname: String, config: BitwardenSdk.ServerCommunicationConfig) async throws {
        let localConfig = try await serverCommunicationConfigStateService.getServerCommunicationConfig(
            hostname: hostname,
        )
        guard let localConfig else {
            try await serverCommunicationConfigStateService.setServerCommunicationConfig(config, hostname: hostname)
            return
        }

        let updatedConfig = localConfig.updateCookieValue(from: config)
        try await serverCommunicationConfigStateService.setServerCommunicationConfig(
            updatedConfig,
            hostname: hostname,
        )
    }
}
