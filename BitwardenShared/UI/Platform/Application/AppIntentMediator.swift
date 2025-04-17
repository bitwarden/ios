import BitwardenKit
import BitwardenSdk

/// A mediator to process `AppIntent` actions.
public protocol AppIntentMediator {
    /// Whether app intents can be run.
    func canRunAppIntents() async -> Bool

    /// Generates a passphrase.
    func generatePassphrase(settings: PassphraseGeneratorRequest) async throws -> String

    /// Locks all available users.
    func lockAllUsers() async throws

    /// Logs out all users.
    func logoutAllUsers() async throws

    /// Opens the generator view.
    func openGenerator() async
}

/// The default implementation of the `AppIntentMediator`.
struct DefaultAppIntentMediator: AppIntentMediator {
    /// The repository used by the application to manage auth data for the UI layer.
    let authRepository: AuthRepository
    /// The service to get server-specified configuration.
    let configService: ConfigService
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter
    /// The repository used by the application to manage generator data for the UI layer.
    let generatorRepository: GeneratorRepository
    /// The service used by the application to manage account state.
    let stateService: StateService

    /// Initializes a `DefaultAppIntentMediator`.
    /// - Parameters:
    ///   - authRepository: The repository used by the application to manage auth data for the UI layer.
    ///   - configService: The service to get server-specified configuration.
    ///   - errorReporter: The service used by the application to report non-fatal errors.
    ///   - stateService: The service used by the application to manage account state.
    public init(
        authRepository: AuthRepository,
        configService: ConfigService,
        errorReporter: ErrorReporter,
        generatorRepository: GeneratorRepository,
        stateService: StateService
    ) {
        self.authRepository = authRepository
        self.configService = configService
        self.errorReporter = errorReporter
        self.generatorRepository = generatorRepository
        self.stateService = stateService
    }

    func canRunAppIntents() async -> Bool {
        await configService.getFeatureFlag(.appIntents)
    }

    func generatePassphrase(settings: PassphraseGeneratorRequest) async throws -> String {
        try await generatorRepository.generatePassphrase(
            settings: settings,
            isPreAuth: true
        )
    }

    func lockAllUsers() async throws {
        try await authRepository.lockAllVaults(isManuallyLocking: true)
    }

    func logoutAllUsers() async throws {
        guard let accounts = try? await stateService.getAccounts(), !accounts.isEmpty else {
            return
        }

        for account in accounts {
            do {
                try await authRepository.logout(userId: account.profile.userId, userInitiated: true)
            } catch {
                errorReporter.log(error: error)
            }
        }
    }

    func openGenerator() async {
        await stateService.addPendingAppIntentAction(.openGenerator)
    }
}
