/// A mediator to process `AppIntent` actions.
public protocol AppIntentMediator {
    /// Whether app intents can be run.
    func canRunAppIntents() async -> Bool

    /// Locks all available users.
    func lockAllUsers() async throws
}

/// The default implementation of the `AppIntentMediator`.
struct DefaultAppIntentMediator: AppIntentMediator {
    /// The repository used by the application to manage auth data for the UI layer.
    let authRepository: AuthRepository
    /// The service to get server-specified configuration.
    let configService: ConfigService

    /// Initializes a `DefaultAppIntentMediator`.
    /// - Parameters:
    ///   - authRepository: The repository used by the application to manage auth data for the UI layer.
    ///   - configService: The service to get server-specified configuration.
    public init(authRepository: AuthRepository, configService: ConfigService) {
        self.authRepository = authRepository
        self.configService = configService
    }

    func canRunAppIntents() async -> Bool {
        await configService.getFeatureFlag(.appIntents)
    }

    func lockAllUsers() async throws {
        try await authRepository.lockAllVaults(isManuallyLocking: true)
    }
}
