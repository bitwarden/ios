/// A mediator to process `AppIntent` actions.
public protocol AppIntentMediator {
    /// Whether app intents can be run.
    func canRunAppIntents() async -> Bool

    /// Locks all available users.
    func lockAllUsers() async throws

    /// Locks the current user.
    func lockCurrentUser() async

    /// Logs out all users.
    func logoutAllUsers() async throws
}

/// The default implementation of the `AppIntentMediator`.
struct DefaultAppIntentMediator: AppIntentMediator {
    /// The repository used by the application to manage auth data for the UI layer.
    let authRepository: AuthRepository
    /// The service to get server-specified configuration.
    let configService: ConfigService
    /// The service used by the application to report non-fatal errors.
    let errorReporter: ErrorReporter
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
        stateService: StateService
    ) {
        self.authRepository = authRepository
        self.configService = configService
        self.errorReporter = errorReporter
        self.stateService = stateService
    }

    func canRunAppIntents() async -> Bool {
        await configService.getFeatureFlag(.appIntents)
    }

    func lockAllUsers() async throws {
        try await authRepository.lockAllVaults(isManuallyLocking: true)
    }

    func lockCurrentUser() async {
        await authRepository.lockVault(userId: nil, isManuallyLocking: true)
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
}
