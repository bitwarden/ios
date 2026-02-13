import BitwardenKit
import BitwardenSdk

final class SdkServerCommunicationConfigRepository: ServerCommunicationConfigRepository {
    // MARK: Properties

    /// The service to get server-specified configuration.
    private let configService: ConfigService

    /// The service used by the application to manage account state.
    private let stateService: StateService

    init(configService: ConfigService, stateService: StateService) {
        self.configService = configService
        self.stateService = stateService
    }

    func get(hostname: String) async throws -> BitwardenSdk.ServerCommunicationConfig? {
        try await stateService.getServerCommunicationConfig(hostname: hostname)
    }

    func save(hostname: String, config: BitwardenSdk.ServerCommunicationConfig) async throws {
        guard let localConfig = try await stateService.getServerCommunicationConfig(hostname: hostname) else {
            try await stateService.setServerCommunicationConfig(config, hostname: hostname)
            return
        }

        let updatedConfig = localConfig.updateCookieValue(from: config)
        try await stateService.setServerCommunicationConfig(
            updatedConfig,
            hostname: hostname,
        )
    }
}
